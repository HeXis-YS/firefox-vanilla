#!/usr/bin/bash
set -e

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

GIT_BRANCH="FIREFOX_128_13_0esr_RELEASE"

if [[ $(uname) == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 gcc sccache git
fi

cd ${WORK_DIR}
git clone --branch=$GIT_BRANCH --single-branch --depth=1 https://github.com/HeXis-YS/firefox
if [[ $1 == "android" ]]; then
  git clone --single-branch --depth=1 https://github.com/HeXis-YS/vendor_google_proprietary_ndk_translation-prebuilt libndk
fi
pushd firefox
git submodule update --init --recursive --depth=1
cp -vf ${REPO_DIR}/mozconfigs/$1 ${GECKO_PATH}/mozconfig

case $1 in
  windows)
    python mach --no-interactive bootstrap --application-choice browser
    hg clone --stream --config format.generaldelta=true --config extensions.fsmonitor= https://hg-edge.mozilla.org/l10n-central/zh-CN ${MOZBUILD_DIR}/l10n-central/zh-CN
    watchman shutdown-server

    # Setup wrapper
    pip install pyinstaller
    pushd ${REPO_DIR}
    rm -rf dist
    pyinstaller --optimize 2 --noupx windows-wrapper.py
    pyinstaller -y windows-wrapper.spec
    cp -r dist/windows-wrapper/* ${MOZBUILD_DIR}/clang/bin/
    pushd ${MOZBUILD_DIR}/clang/bin
    mv clang.exe clang.real.exe
    cp windows-wrapper.exe clang.exe
    cp windows-wrapper.exe clang++.exe
    mv windows-wrapper.exe clang-cl.exe
    popd
    popd

    rustup default 1.81.0
    ;;
  android)
    mkdir -p ~/.gradle
    echo "org.gradle.daemon=false" > ~/.gradle/gradle.properties
    yes N | python mach --no-interactive bootstrap --application-choice mobile_android
    ln -sf $(basename $(realpath ${MOZBUILD_DIR}/jdk/jdk-*)) ${JAVA_HOME}

    ADB="${MOZBUILD_DIR}/android-sdk-linux/platform-tools/adb -s emulator-5554"
    mkdir -p ~/.config/"Android Open Source Project"
    echo -e "[General]\nshowNestedWarning=false\nshowGpuWarning=false" > ~/.config/"Android Open Source Project"/Emulator.conf
    python mach python python/mozboot/mozboot/android.py --avd-manifest=python/mozboot/mozboot/android-avds/android31-x86_64.json --no-interactive
    ANDROID_EMULATOR_HOME=${MOZBUILD_DIR}/android-device ${MOZBUILD_DIR}/android-sdk-linux/emulator/emulator -avd mozemulator-android31-x86_64 -skip-adb-auth -selinux permissive -writable-system -memory 8192 -cores 4 -skin 1280x960 -no-snapstorage -no-snapshot -prop ro.test_harness=true -qemu -cpu host -smp cores=4 &
    $ADB wait-for-device root
    $ADB remount || true
    $ADB reboot
    $ADB wait-for-device root
    $ADB remount
    $ADB push ${WORK_DIR}/libndk/prebuilts/. /system/
    $ADB reboot
    $ADB wait-for-device emu kill

    rm ${MOZBUILD_DIR}/clang/bin/clang ${MOZBUILD_DIR}/clang/bin/clang++
    install -m755 ${REPO_DIR}/android-wrapper.py ${MOZBUILD_DIR}/clang/bin/clang
    install -m755 ${REPO_DIR}/android-wrapper.py ${MOZBUILD_DIR}/clang/bin/clang++

    rustup default nightly-2024-07-31
    rustup target add aarch64-linux-android
    ;;
esac

popd
