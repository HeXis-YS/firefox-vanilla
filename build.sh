#!/bin/bash
source "$(dirname "$0")/paths.sh"

if [[ "$1" != "windows" && "$1" != "linux" && "$!" != "android" ]]; then
    exit 1
fi

pushd $WORK_DIR/firefox

python mach configure
python mach build

case "$1" in
  windows|linux)
    python mach package
    python mach build installers-zh-CN
    ;;
  android)
    export ANDROID_HOME=$(realpath ~/.mozbuild/android-sdk-linux)
    export JAVA_HOME=$(realpath ~/.mozbuild/jdk/jdk-*)
    pushd mobile/android/android-components
    ./gradlew publishToMavenLocal
    popd
    pushd mobile/android/fenix
    ./gradlew assembleRelease
    popd
    ;;
esac

popd
