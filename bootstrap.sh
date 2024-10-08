#!/bin/bash
source "$(dirname "$0")/paths.sh"

readonly BUILD_TAG="FIREFOX_128_2_0esr_RELEASE"

if [[ "$1" != "windows" && "$1" != "linux" && "$!" != "android" ]]; then
    exit 1
fi

if [[ "$(uname)" == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 python3-pip python3-venv gcc mold mercurial watchman sccache
  python3 -m venv "${WORK_DIR}/venv"
  export CFLAGS="-march=native -mtune=native -Ofast -flto -flto-partition=none -fuse-linker-plugin -fgraphite-identity -floop-nest-optimize -fipa-pta -fno-semantic-interposition -fno-common -fdevirtualize-at-ltrans -fno-plt"
  export CXXFLAGS="${CFLAGS}"
  export LDFLAGS="${CFLAGS} -fuse-ld=mold -s -Wl,-O3,--as-needed,--gc-sections,-z,lazy,-z,norelro,-sort-common"
  pip cache purge
  pip install --upgrade pip
  pip install --upgrade mercurial
  unset CFLAGS CXXFLAGS LDFLAGS
fi

cd "${WORK_DIR}"
hg clone --stream --noupdate --config format.generaldelta=true "https://hg.mozilla.org/releases/mozilla-esr128" "firefox"
pushd firefox
hg update --clean --config extensions.fsmonitor= "${BUILD_TAG}"
watchman shutdown-server
patch -p1 -N < "${PATCHES_DIR}/${BUILD_TAG}.diff"
install -v "${MOZCONFIGS_DIR}/$1" "${WORK_DIR}/firefox/mozconfig"

case "$1" in
  windows|linux)
    python mach --no-interactive bootstrap --application-choice browser
    hg clone --stream --config format.generaldelta=true --config extensions.fsmonitor=  "https://hg.mozilla.org/l10n-central/zh-CN" "${MOZBUILD_DIR}/l10n-central/zh-CN)"
    watchman shutdown-server
    ;;
  android)
    python mach --no-interactive bootstrap --application-choice mobile_android
    ;;
esac

popd