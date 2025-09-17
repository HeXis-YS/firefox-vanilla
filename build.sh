#!/usr/bin/bash -e

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

pushd ${WORK_DIR}/firefox

case $1 in
  windows)
    rm -rf workspace
    mkdir -p workspace

    export CLANG_WRAPPER_APPEND="-march=native"
    rm -rf /tmp/* obj-x86_64-pc-windows-msvc
    GEN_PGO=1 python3 mach build
    python3 mach package
    pushd workspace
    JARLOG_FILE=en-US.log python ../mach python ../build/pgo/profileserver.py
    ${MOZBUILD_DIR}/clang/bin/llvm-profdata merge --sparse=true *.profraw -o merged.profdata
    popd

    rm -rf /tmp/* obj-x86_64-pc-windows-msvc
    CSIR_PGO=1 python3 mach build
    python3 mach package
    pushd workspace
    python ../mach python ../build/pgo/profileserver.py
    ${MOZBUILD_DIR}/clang/bin/llvm-profdata merge --sparse=true merged.profdata *.profraw -o merged-cs.profdata
    popd

    export CLANG_WRAPPER_APPEND="-march=znver4"
    rm -rf /tmp/* obj-x86_64-pc-windows-msvc
    USE_PGO=1 python3 mach build
    python3 mach package
    python3 mach build installers-zh-CN

    mkdir -p ${WORK_DIR}/release
    cp -vr workspace/*.profdata ${WORK_DIR}/release/
    cp -v obj-x86_64-pc-windows-msvc/dist/install/sea/*.exe ${WORK_DIR}/release/
    ;;
  android)
    sudo rm -rf /builds
    sudo mkdir /builds
    sudo chown $(stat -c %u:%g ~) /builds

    export CLANG_WRAPPER_PREPEND="-march=armv8-a+crypto+crc"
    export RUST_WRAPPER_APPEND="-C target-feature=+crypto,+crc"
    rm -rf obj-aarch64-unknown-linux-android
    GEN_PGO=1 python3 mach build
    rm -rf workspace/*.profraw
    sed -i '/^$/d' ${MOZBUILD_DIR}/android-device/avd/mozemulator-android*.ini
    MOZ_FETCHES_DIR=${MOZBUILD_DIR} python3 mach python testing/mozharness/scripts/android_emulator_pgo.py \
      --config-file testing/mozharness/configs/android/android_common.py \
      --config-file testing/mozharness/configs/android/android-aarch64-profile-generation.py \
      --config-file testing/mozharness/configs/android/android_pgo.py \
      --installer-path obj-aarch64-unknown-linux-android/gradle/build/mobile/android/test_runner/outputs/apk/debug/test_runner-debug.apk
    ${MOZBUILD_DIR}/android-sdk-linux/platform-tools/adb -s emulator-5554 emu kill
    pushd workspace
    ${MOZBUILD_DIR}/clang/bin/llvm-profdata merge --sparse=true *.profraw -o merged.profdata
    popd

    rm -rf obj-aarch64-unknown-linux-android
    CSIR_PGO=1 python3 mach build
    rm -rf workspace/*.profraw
    sed -i '/^$/d' ${MOZBUILD_DIR}/android-device/avd/mozemulator-android*.ini
    MOZ_FETCHES_DIR=${MOZBUILD_DIR} python3 mach python testing/mozharness/scripts/android_emulator_pgo.py \
      --config-file testing/mozharness/configs/android/android_common.py \
      --config-file testing/mozharness/configs/android/android-aarch64-profile-generation.py \
      --config-file testing/mozharness/configs/android/android_pgo.py \
      --installer-path obj-aarch64-unknown-linux-android/gradle/build/mobile/android/test_runner/outputs/apk/debug/test_runner-debug.apk
    ${MOZBUILD_DIR}/android-sdk-linux/platform-tools/adb -s emulator-5554 emu kill
    pushd workspace
    ${MOZBUILD_DIR}/clang/bin/llvm-profdata merge --sparse=true merged.profdata *.profraw -o merged-cs.profdata
    popd

    unset CLANG_WRAPPER_PREPEND
    export CLANG_WRAPPER_APPEND="-mcpu=cortex-x3+crypto+sha3+nosve -mtune=cortex-a510"
    export RUST_WRAPPER_APPEND="-C target-cpu=cortex-x3 -Z tune-cpu=cortex-a510 -C target-feature=+crypto,+sha3,-sve"
    rm -rf obj-aarch64-unknown-linux-android
    USE_PGO=1 python3 mach build
    pushd mobile/android/fenix
    # unset ANDROID_SDK_ROOT
    ./gradlew assembleRelease
    popd
    mkdir -p ${WORK_DIR}/release
    cp -v workspace/* \
      obj-aarch64-unknown-linux-android/gradle/build/mobile/android/fenix/app/outputs/apk/fenix/release/app-fenix-arm64-v8a-release-unsigned.apk \
      ${WORK_DIR}/release/
    ;;
esac

if [[ -n $USE_SCCACHE ]]; then
    sccache --stop-server
fi

popd
