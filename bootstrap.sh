#!/bin/bash
source "$(dirname "$0")/paths.sh"

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

hg clone --stream --noupdate --config format.generaldelta=true "https://hg.mozilla.org/releases/mozilla-esr128" "firefox"
pushd firefox
hg update --clean --config extensions.fsmonitor= "FIREFOX_128_2_0esr_RELEASE"
popd