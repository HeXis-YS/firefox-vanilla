#!/usr/bin/env bash
set -eo pipefail

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

GIT_BRANCH="FIREFOX_140_7_0esr_RELEASE"

if [[ $(uname) == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 python3-pip python3-venv git libx11-6 procps libnotify-bin
fi

cd $_WORK_DIR
git clone -b $GIT_BRANCH --depth 1 --single-branch --no-tags https://github.com/HeXis-YS/firefox

pushd firefox

cp -vf $_REPO_DIR/mozconfigs/$1 mozconfig

case $1 in
  windows)
    python3 mach --no-interactive bootstrap --application-choice browser
    git clone --depth 1 --single-branch --no-tags https://github.com/mozilla-l10n/firefox-l10n

    # Setup wrapper
    pip install pyinstaller
    pushd $_WORK_DIR
    rm -rf dist
    pyinstaller --optimize 2 --noupx $_REPO_DIR/wrappers/windows/clang.py
    pyinstaller -y clang.spec
    pyinstaller --optimize 2 --noupx $_REPO_DIR/wrappers/windows/rust.py
    pyinstaller -y rust.spec
    popd

    pushd $_MOZBUILD_DIR/clang/bin
    mv clang.exe clang.real.exe
    powershell del clang++.exe
    powershell del clang-cl.exe
    cp -r $_WORK_DIR/dist/clang/. ./
    cp clang.exe clang++.exe
    cp clang.exe clang-cl.exe
    popd

    rustup default nightly-2025-02-17

    pushd $(dirname $(~/.cargo/bin/rustup which rustc))
    mv rustc.exe rustc.real.exe
    cp -r $_WORK_DIR/dist/rust/. ./
    mv rust.exe rustc.exe
    popd
    ;;
  android)
    pushd $_WORK_DIR
      # Clone microG
      MICROG_VERSION=v0.3.11.250932
      git clone -b $MICROG_VERSION --depth 1 --single-branch --no-tags https://github.com/microg/GmsCore microg
    popd

    # Config gradle
    mkdir -p ~/.gradle
    echo "org.gradle.daemon=false" > ~/.gradle/gradle.properties

    # Config AVD
    mkdir -p ~/.config/"Android Open Source Project"
    echo -e "[General]\nshowNestedWarning=false\nshowGpuWarning=false" > ~/.config/"Android Open Source Project"/Emulator.conf

    # Bootstrap building environments
    yes 'N' | python3 mach --no-interactive bootstrap --application-choice mobile_android || true
    pushd $_MOZBUILD_DIR
      rm -rf toolchains android-device/avd/* android-sdk-linux/system-images/*
      if [ -n $JAVA_HOME_17_X64 ]; then
        rm -rf jdk/jdk-17.0.15+6
        ln -nsf $JAVA_HOME_17_X64 jdk/jdk-17.0.15+6
      fi
    popd

    # Setup AVD
    yes 'N' | python3 mach python python/mozboot/mozboot/android.py --avd-manifest=$_REPO_DIR/android31-x86_64.json --no-interactive || true

    pushd $_MOZBUILD_DIR
      mkdir -p $_WORK_DIR/mozbuild-cache
      mv android-device/avd $_WORK_DIR/mozbuild-cache/
      mv android-sdk-linux/system-images $_WORK_DIR/mozbuild-cache/
      ln -nsf mozbuild-cache cache
      ln -nsf ../cache/avd android-device/avd
      ln -nsf ../cache/system-images android-sdk-linux/system-images

      # Install mold linker
      MOLD_URL=$(curl -fsSL "https://api.github.com/repos/rui314/mold/releases/latest" | jq -r '.assets[] | select(.name | test("^mold-.*-x86_64-linux.tar.gz$")) | .browser_download_url')
      curl -fsSL $MOLD_URL | tar --strip-components=1 -C clang -xzf-

      # Setup clang wrapper
      pushd clang/bin
        install -m0755 $_REPO_DIR/wrappers/android/clang.py clang.py
        mv clang clang.real
        ln -nsf clang.py clang
        # ln -nsf clang.py clang++
      popd
    popd

    # Setup rust wrapper
    source $HOME/.cargo/env
    rustup default nightly-2025-02-17
    rustup target add aarch64-linux-android
    pushd $(dirname $(~/.cargo/bin/rustup which rustc))
      [ ! -f rustc.real ] && mv rustc rustc.real
      install -m0755 $_REPO_DIR/wrappers/android/rust.py rust.py
      ln -nsf rust.py rustc
    popd
    ;;
esac

popd
