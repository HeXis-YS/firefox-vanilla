#!/usr/bin/bash
set -e

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

GIT_BRANCH="FIREFOX_128_5_2esr_RELEASE"
VERSION_STRING="128.5.2 ESR"

if [[ $(uname) == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 gcc sccache git
fi

cd ${WORK_DIR}
git clone --branch=$GIT_BRANCH --single-branch --depth=1 https://github.com/HeXis-YS/firefox
pushd firefox
rm -rf ${GECKO_PATH}/modules/zlib/src/*
cp -vrf ${REPO_DIR}/custom/* ${GECKO_PATH}/
cp -vf ${REPO_DIR}/mozconfigs/$1 ${GECKO_PATH}/mozconfig
patch -p1 -N < "${PATCHES_DIR}/lto.patch"
patch -p1 -N < "${PATCHES_DIR}/visibility.patch"

case $1 in
  windows)
    patch -p1 -N < "${PATCHES_DIR}/pgo.patch"
    cat ${REPO_DIR}/user.js >> browser/app/profile/firefox.js
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
    ;;
  android)
    patch -p1 -N < "${PATCHES_DIR}/binary-check.patch"
    patch -p1 -N < "${PATCHES_DIR}/android-pgo.patch"
    patch -p1 -N < "${PATCHES_DIR}/android.patch"
    cat ${REPO_DIR}/user.js >> mobile/android/app/geckoview-prefs.js
    pushd mobile/android/fenix
    sed -i \
        -e 's/applicationId "org.mozilla"/applicationId "org.hexis"/' \
        -e "s/\${Config.releaseVersionName(project)}/${VERSION_STRING}/" \
        -e 's/"sharedUserId": "org.mozilla.firefox.sharedID"/"sharedUserId": "org.hexis.firefox.sharedID"/' \
        -e '/CRASH_REPORTING/s/true/false/' \
        -e '/TELEMETRY/s/true/false/' \
        -e 's/include ".*"/include "arm64-v8a"/' \
        app/build.gradle
    sed -i \
        -e '/android:targetPackage/s/org.mozilla.firefox/org.hexis.firefox/' \
        app/src/release/res/xml/shortcuts.xml
    sed -i \
        -e 's/aboutConfigEnabled(.*)/aboutConfigEnabled(true)/' \
        app/src/*/java/org/mozilla/fenix/*/GeckoProvider.kt
    echo 'https://assets.mozilla.net/mobile-wallpapers/android' > .wallpaper_url
    popd
    mkdir -p ~/.gradle
    echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties
    yes N | python mach --no-interactive bootstrap --application-choice mobile_android
    mkdir -p ~/.config/"Android Open Source Project"
    echo -e "\n[General]\nshowNestedWarning=false" >> ~/.config/"Android Open Source Project"/Emulator.conf
    ln -sf $(basename $(realpath ${MOZBUILD_DIR}/jdk/jdk-*)) ${JAVA_HOME}
    python mach python python/mozboot/mozboot/android.py --avd-manifest=python/mozboot/mozboot/android-avds/android31-x86_64.json --no-interactive

    rm ${MOZBUILD_DIR}/clang/bin/clang ${MOZBUILD_DIR}/clang/bin/clang++
    install -m755 ${REPO_DIR}/android-wrapper.py ${MOZBUILD_DIR}/clang/bin/clang
    install -m755 ${REPO_DIR}/android-wrapper.py ${MOZBUILD_DIR}/clang/bin/clang++

    rustup default nightly-2024-07-31
    rustup target add aarch64-linux-android
    ;;
esac

popd
