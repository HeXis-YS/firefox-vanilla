#!/usr/bin/bash
set -e

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

pushd ${WORK_DIR}/firefox

case $1 in
  windows)
    rm -rf /tmp/* obj-x86_64-pc-windows-msvc
    GEN_PGO=1 python mach build
    python mach package
    mkdir workspace
    pushd workspace
    JARLOG_FILE=en-US.log python ../mach python ../build/pgo/profileserver.py
    ${MOZBUILD_DIR}/clang/bin/llvm-profdata merge --sparse=true *.profraw -o merged.profdata
    popd

    rm -rf /tmp/* obj-x86_64-pc-windows-msvc
    CSIR_PGO=1 python mach build
    python mach package
    pushd workspace
    python ../mach python ../build/pgo/profileserver.py
    ${MOZBUILD_DIR}/clang/bin/llvm-profdata merge --sparse=true merged.profdata *.profraw -o merged-cs.profdata
    popd

    rm -rf /tmp/* obj-x86_64-pc-windows-msvc
    USE_PGO=1 python mach build
    python mach package
    python mach build installers-zh-CN

    mkdir -p ${WORK_DIR}/release
    cp -vr workspace/*.profdata ${WORK_DIR}/release/
    cp -v obj-x86_64-pc-windows-msvc/dist/install/sea/*.exe ${WORK_DIR}/release/
    ;;
  android)
    rm -rf obj-aarch64-unknown-linux-android
    export PREPEND_FLAGS="-march=armv8-a+crypto+crc"
    GEN_PGO=1 python mach build
    rm -rf workspace/*.profraw
    sed -i '/^$/d' ${MOZBUILD_DIR}/android-device/avd/mozemulator-android*.ini
    MOZ_FETCHES_DIR=${MOZBUILD_DIR} python mach python testing/mozharness/scripts/android_emulator_pgo.py \
      --config-file testing/mozharness/configs/android/android_common.py \
      --config-file testing/mozharness/configs/android/android-aarch64-profile-generation.py \
      --config-file testing/mozharness/configs/android/android_pgo.py \
      --installer-path obj-aarch64-unknown-linux-android/gradle/build/mobile/android/test_runner/outputs/apk/withGeckoBinaries/debug/test_runner-withGeckoBinaries-debug.apk
    ${MOZBUILD_DIR}/android-sdk-linux/platform-tools/adb -s emulator-5554 emu kill
    pushd workspace
    ${MOZBUILD_DIR}/clang/bin/llvm-profdata merge --sparse=true *.profraw -o merged.profdata
    popd

    rm -rf obj-aarch64-unknown-linux-android
    CSIR_PGO=1 python mach build
    rm -rf workspace/*.profraw
    sed -i '/^$/d' ${MOZBUILD_DIR}/android-device/avd/mozemulator-android*.ini
    MOZ_FETCHES_DIR=${MOZBUILD_DIR} python mach python testing/mozharness/scripts/android_emulator_pgo.py \
      --config-file testing/mozharness/configs/android/android_common.py \
      --config-file testing/mozharness/configs/android/android-aarch64-profile-generation.py \
      --config-file testing/mozharness/configs/android/android_pgo.py \
      --installer-path obj-aarch64-unknown-linux-android/gradle/build/mobile/android/test_runner/outputs/apk/withGeckoBinaries/debug/test_runner-withGeckoBinaries-debug.apk
    ${MOZBUILD_DIR}/android-sdk-linux/platform-tools/adb -s emulator-5554 emu kill
    pushd workspace
    ${MOZBUILD_DIR}/clang/bin/llvm-profdata merge --sparse=true merged.profdata *.profraw -o merged-cs.profdata
    popd

    rm -rf obj-aarch64-unknown-linux-android
    unset PREPEND_FLAGS
    export APPEND_FLAGS="-mcpu=cortex-x3+crypto+sha3+nosve -mtune=cortex-a510"
    USE_PGO=1 python mach build
    pushd mobile/android/fenix
    ./gradlew assembleRelease
    popd
    mkdir -p ${WORK_DIR}/release
    cp -vr workspace/* ${WORK_DIR}/release/
    cp -v mobile/android/fenix/app/build/outputs/apk/fenix/release/app-fenix-arm64-v8a-release-unsigned.apk ${WORK_DIR}/release/
    ;;
esac

if [[ -n $USE_SCCACHE ]]; then
    sccache --stop-server
fi

popd
