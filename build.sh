#!/usr/bin/env bash
set -euo pipefail

prepare_obj_dir1() {
  rm -rf obj $_TMP_DIR/obj
  mkdir -p $_TMP_DIR/obj
  ln -nsf $_TMP_DIR/obj obj-aarch64-unknown-linux-android
}

prepare_obj_dir2() {
  ln -nsf $_CACHE_DIR/gradle obj-aarch64-unknown-linux-android/gradle
}

run_pgo_emulator() {
  mv $_TMP_DIR/obj obj
  ln -nsf obj obj-aarch64-unknown-linux-android
  cp -r $_MOZBUILD_DIR/mozbuild-cache $_TMP_DIR/
  rm -rf workspace/*.profraw
  MOZ_FETCHES_DIR=$_MOZBUILD_DIR python3 mach python testing/mozharness/scripts/android_emulator_pgo.py \
    --config-file testing/mozharness/configs/android/android_common.py \
    --config-file testing/mozharness/configs/android/android-aarch64-profile-generation.py \
    --config-file testing/mozharness/configs/android/android_pgo.py \
    --installer-path obj-aarch64-unknown-linux-android/gradle/build/mobile/android/test_runner/outputs/apk/debug/test_runner-debug.apk
  $_MOZBUILD_DIR/android-sdk-linux/platform-tools/adb -s emulator-5554 emu kill || true
  rm -rf $_TMP_DIR/mozbuild-cache
  pushd workspace
  llvm-profdata merge --sparse=true *.profraw -o merged.profdata
  popd
}

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

# export WRAPPER_WRITE_LOG=1
# rm -f /tmp/clang-wrapper-log.txt /tmp/rust-wrapper-log.txt

case $1 in
  windows)
    pushd $_WORK_DIR/firefox

    # export TREAT_HOST_AS_TARGET=1

    rm -rf workspace
    mkdir -p workspace

    export CLANG_WRAPPER_TARGET_APPEND="-march=native"
    export CLANG_CL_WRAPPER_TARGET_APPEND="-march=native"
    export RUST_WRAPPER_TARGET_APPEND="-C target-cpu=native"
    rm -rf obj-x86_64-pc-windows-msvc
    PGO_STAGE=1 python3 mach build
    python3 mach package
    pushd workspace
    JARLOG_FILE=en-US.log python3 ../mach python ../build/pgo/profileserver.py
    llvm-profdata merge --sparse=true *.profraw -o merged.profdata
    popd

    rm -rf obj-x86_64-pc-windows-msvc
    PGO_STAGE=2 python3 mach build
    python3 mach package
    pushd workspace
    python3 ../mach python ../build/pgo/profileserver.py
    llvm-profdata merge --sparse=true merged.profdata *.profraw -o merged-cs.profdata
    popd

    export CLANG_WRAPPER_TARGET_APPEND="-march=znver4"
    export CLANG_CL_WRAPPER_TARGET_APPEND="-march=znver4"
    export RUST_WRAPPER_TARGET_APPEND="-C target-cpu=znver4"
    rm -rf obj-x86_64-pc-windows-msvc
    PGO_STAGE=3 python3 mach build
    python3 mach package
    MOZ_ARTIFACT_FILE=$(realpath -s obj-x86_64-pc-windows-msvc/dist/$(cat obj-x86_64-pc-windows-msvc/dist/package_name.txt)) python3 mach build installers-zh-CN

    mkdir -p $_WORK_DIR/release
    cp -vr workspace/*.profdata $_WORK_DIR/release/
    cp -v obj-x86_64-pc-windows-msvc/dist/install/sea/*.exe $_WORK_DIR/release/

    popd
    ;;
  android)
    pushd microg
    ./gradlew -x javaDocReleaseGeneration \
      :play-services-ads-identifier:publishToMavenLocal \
      :play-services-base:publishToMavenLocal \
      :play-services-basement:publishToMavenLocal \
      :play-services-fido:publishToMavenLocal \
      :play-services-tasks:publishToMavenLocal
    popd

    sudo rm -rf /builds
    sudo mkdir /builds
    sudo chown $(stat -c %u:%g ~) /builds

    mkdir -p $_CACHE_DIR/gradle

    export CLANG_WRAPPER_TARGET_PREPEND="-march=armv8-a+crypto+crc"
    export RUST_WRAPPER_TARGET_APPEND="-C target-feature=+crypto,+crc"

    # Stage 1
    mv firefox $_TMP_DIR/
    ln -nsf $_TMP_DIR/firefox firefox
    pushd firefox
    prepare_obj_dir2
    PGO_STAGE=1 python3 mach build
    popd
    rm -f firefox
    mv $_TMP_DIR/firefox ./

    run_pgo_emulator
    pushd workspace
    llvm-profdata merge --sparse=true *.profraw -o merged.profdata
    popd

    # Stage 2
    mv firefox $_TMP_DIR/
    ln -nsf $_TMP_DIR/firefox firefox
    pushd firefox
    prepare_obj_dir2
    PGO_STAGE=2 python3 mach build
    popd
    rm -f firefox
    mv $_TMP_DIR/firefox ./

    run_pgo_emulator
    pushd workspace
    llvm-profdata merge --sparse=true merged.profdata *.profraw -o merged-cs.profdata
    popd

    unset CLANG_WRAPPER_TARGET_PREPEND
    export CLANG_WRAPPER_TARGET_APPEND="-mcpu=cortex-x3+crypto+sha3+nosve -mtune=cortex-a510"
    export RUST_WRAPPER_TARGET_APPEND="-C target-cpu=cortex-x3 -Z tune-cpu=cortex-a510 -C target-feature=+crypto,+sha3,-sve"

    # Stage 3
    prepare_obj_dir1
    prepare_obj_dir2
    PGO_STAGE=3 python3 mach build

    pushd mobile/android/fenix
    ./gradlew assembleRelease
    popd
    mkdir -p $_WORK_DIR/release
    cp -v workspace/* \
      obj-aarch64-unknown-linux-android/gradle/build/mobile/android/fenix/app/outputs/apk/fenix/release/app-fenix-arm64-v8a-release-unsigned.apk \
      $_WORK_DIR/release/

    popd
    ;;
esac

if [[ -n $USE_SCCACHE ]]; then
    sccache --stop-server
fi
