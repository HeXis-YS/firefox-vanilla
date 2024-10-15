#!/bin/bash
if [[ "$1" != "windows" && "$1" != "android" ]]; then
    exit 1
fi

source "$(dirname "$0")/paths.sh"

HG_TAG="FIREFOX_128_3_1esr_RELEASE"
VERSION_STRING="128.3.1 ESR"

if [[ "$(uname)" == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 python3-pip python3-venv gcc watchman sccache git
  python3 -m venv "${WORK_DIR}/venv"
  pip install --upgrade mercurial
fi

cd "${WORK_DIR}"
hg clone --stream --noupdate --config format.generaldelta=true "https://hg.mozilla.org/releases/mozilla-esr128" firefox
pushd firefox
hg update --clean --config extensions.fsmonitor= "${HG_TAG}"
patch -p1 -N < "${REPO_DIR}"/patches/pgo.patch
cp -vrf "${REPO_DIR}/custom/"* "${WORK_DIR}/firefox/"
cp -vf "${REPO_DIR}/mozconfigs/$1" "${WORK_DIR}/firefox/mozconfig"

case "$1" in
  windows)
    python mach --no-interactive bootstrap --application-choice browser
    hg clone --stream --config format.generaldelta=true --config extensions.fsmonitor=  "https://hg.mozilla.org/l10n-central/zh-CN" "${MOZBUILD_DIR}/l10n-central/zh-CN)"
    ;;
  android)
    pushd mobile/android/fenix
    sed -i \
        -e 's/applicationId "org.mozilla"/applicationId "org.hexis"/' \
        -e "s/Config.releaseVersionName(project)/\"${VERSION_STRING}\"/" \
        -e 's/"sharedUserId": "org.mozilla.firefox.sharedID"/"sharedUserId": "org.hexis.firefox.sharedID"/' \
        -e '/CRASH_REPORTING/s/true/false/' \
        -e '/TELEMETRY/s/true/false/' \
        -e "s/include \".*\"/include \"arm64-v8a\"/" \
        app/build.gradle
    sed -i \
        -e '/android:targetPackage/s/org.mozilla.firefox/org.hexis.firefox/' \
        app/src/release/res/xml/shortcuts.xml
    sed -i \
        -e 's/aboutConfigEnabled(.*)/aboutConfigEnabled(true)/' \
        app/src/*/java/org/mozilla/fenix/*/GeckoProvider.kt
    popd
    yes N | python mach --no-interactive bootstrap --application-choice mobile_android
    python mach python python/mozboot/mozboot/android.py --avd-manifest="python/mozboot/mozboot/android-avds/android31-x86_64.json" --no-interactive
    ;;
esac

watchman shutdown-server

popd