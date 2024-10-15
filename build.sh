#!/bin/bash
if [[ "$1" != "windows" && "$1" != "android" ]]; then
    exit 1
fi

source "$(dirname "$0")/paths.sh"

pushd ${WORK_DIR}/firefox

case "$1" in
  windows)
    rm -rf obj-x86_64-pc-windows-msvc
    GEN_PGO=1 python mach build
    python mach package
    mkdir workspace
    rm -f *.profraw
    pushd workspace
    LLVM_PROFDATA="${MOZBUILD_DIR}/clang/bin/llvm-profdata" JARLOG_FILE="en-US.log" python ../mach python ../build/pgo/profileserver.py
    popd
    rm -rf obj-x86_64-pc-windows-msvc
    USE_PGO=1 python mach build
    python mach package
    python mach build installers-zh-CN
    cp -vr workspace "${WORK_DIR}/release"
    cp -v "obj-x86_64-pc-windows-msvc/dist/install/sea/*.exe" "${WORK_DIR}/release/"
    ;;
  android)
    rm -rf obj-aarch64-unknown-linux-android
    GEN_PGO=1 python mach build
    python python mach python testing/mozharness/scripts/android_emulator_pgo_local.py \
      --config-file testing/mozharness/configs/android/android_common.py \
      --config-file testing/mozharness/configs/android/android-aarch64-profile-generation_local.py \
      --config-file testing/mozharness/configs/android/android_pgo.py \
      --installer-path obj-aarch64-unknown-linux-android/gradle/build/mobile/android/test_runner/outputs/apk/withGeckoBinaries/debug/test_runner-withGeckoBinaries-debug.apk
    rm -rf obj-aarch64-unknown-linux-android
    USE_PGO=1 python mach build
    pushd mobile/android/fenix
    ./gradlew assembleRelease
    popd
    ;;
esac

if [[ -n "USE_SCCACHE" ]]; then
    sccache --stop-server
fi

popd
