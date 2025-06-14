#!/usr/bin/bash
set -e

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

HG_TAG="FIREFOX_128_5_2esr_RELEASE"
VERSION_STRING="128.5.2 ESR"

if [[ $(uname) == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 python3-pip python3-venv gcc watchman sccache git
  python3 -m venv ${WORK_DIR}/venv
  pip install --upgrade mercurial
fi

cd ${WORK_DIR}
hg clone --stream --noupdate --config format.generaldelta=true https://hg.mozilla.org/releases/mozilla-esr128 firefox
pushd firefox
hg update --clean --config extensions.fsmonitor= ${HG_TAG}
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
    hg clone --stream --config format.generaldelta=true --config extensions.fsmonitor= https://hg.mozilla.org/l10n-central/zh-CN ${MOZBUILD_DIR}/l10n-central/zh-CN
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

    rm ${MOZBUILD_DIR}/clang/bin/clang
    install -m755 ${REPO_DIR}/android-wrapper.py ${MOZBUILD_DIR}/clang/bin/clang

    rustup default 1.81.0
    rustup target add aarch64-linux-android
    ;;
esac

watchman shutdown-server

popd
