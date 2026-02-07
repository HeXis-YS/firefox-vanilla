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
      rm -rf android-device/avd/* android-sdk-linux/system-images/*
      if [ -n $JAVA_HOME_17_X64 ]; then
        rm -rf jdk/jdk-17.0.15+6
        ln -nsf $JAVA_HOME_17_X64 jdk/jdk-17.0.15+6
      fi
    popd

    # Setup AVD
    yes 'N' | python3 mach python python/mozboot/mozboot/android.py --avd-manifest=$_REPO_DIR/android33-x86_64.json --no-interactive || true

    # Setup libhoudini for AVD
    sudo apt install -y udev
    sudo groupadd -r kvm || true
    sudo gpasswd -a $(whoami) kvm || true
    ADB="$_MOZBUILD_DIR/android-sdk-linux/platform-tools/adb -s emulator-5554"
    git clone --depth 1 --single-branch --no-tags https://github.com/HeXis-YS/vendor_intel_proprietary_houdini /tmp/libhoudini
    ANDROID_EMULATOR_HOME=$_MOZBUILD_DIR/android-device $_MOZBUILD_DIR/android-sdk-linux/emulator/emulator \
      -avd mozemulator-android33-x86_64 \
      -skip-adb-auth \
      -selinux permissive \
      -memory 4096 \
      -cores 4 \
      -skin 1280x960 \
      -no-audio \
      -no-window \
      -no-boot-anim \
      -writable-system \
      -no-snapstorage \
      -qemu -enable-kvm -cpu host -smp cores=4 &
    $ADB wait-for-device root
    $ADB remount || true
    $ADB reboot
    $ADB wait-for-device root
    $ADB remount
    $ADB push /tmp/libhoudini/prebuilts/. /system/
    $ADB shell 'echo "ro.product.cpu.abilist=x86_64,x86,arm64-v8a" >> /system/build.prop'
    $ADB shell 'echo "ro.product.cpu.abilist64=x86_64,arm64-v8a" >> /system/build.prop'
    $ADB shell 'echo "ro.dalvik.vm.native.bridge=libhoudini.so" >> /system/build.prop'
    $ADB shell 'echo "ro.enable.native.bridge.exec64=1" >> /system/build.prop'
    $ADB shell 'echo "ro.dalvik.vm.isa.arm64=x86_64" >> /system/build.prop'
    $ADB reboot
    $ADB wait-for-device emu kill
    wait
    rm -rf /tmp/libhoudini

    pushd $_MOZBUILD_DIR
      mkdir -p cache.real
      mv android-device/avd cache.real/
      mv android-sdk-linux/system-images cache.real/
      ln -nsf cache.real cache
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
