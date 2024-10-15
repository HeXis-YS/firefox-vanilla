#!/bin/bash
source "$(dirname "$0")/paths.sh"

readonly BUILD_TAG="FIREFOX_128_3_1esr_RELEASE"

if [[ "$1" != "windows" && "$1" != "android" ]]; then
    exit 1
fi

if [[ "$(uname)" == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 python3-pip python3-venv gcc watchman sccache git
  python3 -m venv "${WORK_DIR}/venv"
  pip install --upgrade mercurial
fi

cd "${WORK_DIR}"
hg clone --stream --noupdate --config format.generaldelta=true "https://hg.mozilla.org/releases/mozilla-esr128" firefox
pushd firefox
hg update --clean --config extensions.fsmonitor= "${BUILD_TAG}"
watchman shutdown-server
patch -p1 -N < "${REPO_DIR}/patches/pgo.patch"
cp -vrf "${REPO_DIR}/custom/*" ./
cp -vf "${REPO_DIR}/mozconfigs/$1" "${WORK_DIR}/firefox/mozconfig"

case "$1" in
  windows)
    mach --no-interactive bootstrap --application-choice browser
    hg clone --stream --config format.generaldelta=true --config extensions.fsmonitor=  "https://hg.mozilla.org/l10n-central/zh-CN" "${MOZBUILD_DIR}/l10n-central/zh-CN)"
    watchman shutdown-server
    ;;
  android)
    pushd mobile/android/fenix
    sed -i \
        -e 's|applicationId "org.mozilla"|applicationId "org.hexis"|' \
        -e "s/Config.releaseVersionName(project)/\"128.3.1 ESR\"/" \
        -e 's|"sharedUserId": "org.mozilla.firefox.sharedID"|"sharedUserId": "org.hexis.firefox.sharedID"|' \
        -e '/CRASH_REPORTING/s/true/false/' \
        -e '/TELEMETRY/s/true/false/' \
        app/build.gradle
    sed -i \
        -e '/android:targetPackage/s/org.mozilla.firefox/org.hexis.firefox/' \
        app/src/release/res/xml/shortcuts.xml
    sed -i \
        -e 's/aboutConfigEnabled(.*)/aboutConfigEnabled(true)/' \
        app/src/*/java/org/mozilla/fenix/*/GeckoProvider.kt
    sed -i -e "s/include \".*\"/include \"arm64-v8a\"/" app/build.gradle
    popd
    yes N | mach --no-interactive bootstrap --application-choice mobile_android
    mach python python/mozboot/mozboot/android.py --avd-manifest="python/mozboot/mozboot/android-avds/android31-x86_64.json" --no-interactive
    ;;
esac

popd