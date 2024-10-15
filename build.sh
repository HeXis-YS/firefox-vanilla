#!/bin/bash
source "$(dirname "$0")/paths.sh"

if [[ "$1" != "windows" && "$1" != "android" ]]; then
    exit 1
fi

pushd ${WORK_DIR}/firefox

case "$1" in
  windows)
    GEN_PGO=1 mach build
    "${MOZBUILD_DIR}/sccache/sccache" --stop-server
    mach package
    mkdir workspace
    pushd workspace
    LLVM_PROFDATA="${MOZBUILD_DIR}/clang/bin/llvm-profdata" JARLOG_FILE="en-US.log" python ../mach python ../build/pgo/profileserver.py
    popd
    rm -rf obj-x86_64-pc-windows-msvc
    USE_PGO=1 mach build
    "${MOZBUILD_DIR}/sccache/sccache" --stop-server
    mach package
    mach build installers-zh-CN
    cp -v obj-x86_64-pc-windows-msvc/jarlog/en-US.log "${WORK_DIR}/"
    cp -v obj-x86_64-pc-windows-msvc/instrumented/merged.profdata "${WORK_DIR}/"
    cp -v "obj-x86_64-pc-windows-msvc/dist/install/sea/*.exe" "${WORK_DIR}/"
    ;;
  android)
    GEN_PGO=1 mach build
    "${MOZBUILD_DIR}/sccache/sccache" --stop-server
    python mach python testing/mozharness/scripts/android_emulator_pgo_local.py \
      --config-file testing/mozharness/configs/android/android_common.py \
      --config-file testing/mozharness/configs/android/android-aarch64-profile-generation_local.py \
      --config-file testing/mozharness/configs/android/android_pgo.py \
      --installer-path obj-aarch64-unknown-linux-android/gradle/build/mobile/android/test_runner/outputs/apk/withGeckoBinaries/debug/test_runner-withGeckoBinaries-debug.apk
    USE_PGO=1 mach build
    "${MOZBUILD_DIR}/sccache/sccache" --stop-server
    pushd mobile/android/fenix
    ./gradlew assembleRelease
    popd
    ;;
esac

popd
