#!/bin/bash
source "$(dirname "$0")/paths.sh"

if [[ "$1" != "windows" && "$1" != "android" ]]; then
    exit 1
fi

pushd $WORK_DIR/firefox

python mach configure
python mach build
~/.mozbuild/sccache/sccache --stop-server

case "$1" in
  windows)
    python mach package
    sed -i -e 's/ac_add_options MOZ_PGO=1/#ac_add_options MOZ_PGO=1/g' mozconfig
    python mach build installers-zh-CN
    cp -v obj-x86_64-pc-windows-msvc/jarlog/en-US.log "${WORK_DIR}/"
    cp -v obj-x86_64-pc-windows-msvc/instrumented/merged.profdata "${WORK_DIR}/"
    cp -v "obj-x86_64-pc-windows-msvc/dist/install/sea/*.exe" "${WORK_DIR}/"
    ;;
  android)
    export ANDROID_HOME=$(realpath ${MOZBUILD_DIR}/android-sdk-linux)
    export JAVA_HOME=$(realpath ${MOZBUILD_DIR}/jdk/jdk-*)
    export GECKO_PATH=$(realpath .)
    python mach python testing/mozharness/scripts/android_emulator_pgo_local.py \
      --config-file testing/mozharness/configs/android/android_common.py \
      --config-file testing/mozharness/configs/android/android-aarch64-profile-generation_local.py \
      --config-file testing/mozharness/configs/android/android_pgo.py \
      --installer-path obj-aarch64-unknown-linux-android/gradle/build/mobile/android/test_runner/outputs/apk/withGeckoBinaries/debug/test_runner-withGeckoBinaries-debug.apk
    pushd mobile/android/fenix
    ./gradlew assembleRelease
    popd
    ;;
esac

popd
