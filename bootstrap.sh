#!/usr/bin/bash -e

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

GIT_BRANCH="FIREFOX_140_7_0esr_RELEASE"

if [[ $(uname) == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 python3-pip python3-venv git libx11-6 procps libnotify-bin
fi

cd $WORK_DIR
git clone -b $GIT_BRANCH --depth 1 --single-branch --no-tags https://github.com/HeXis-YS/firefox

pushd firefox
cp -vf $REPO_DIR/mozconfigs/$1 $GECKO_PATH/mozconfig

case $1 in
  windows)
    python3 mach --no-interactive bootstrap --application-choice browser
    git clone --depth 1 --single-branch --no-tags https://github.com/mozilla-l10n/firefox-l10n

    # Setup wrapper
    pip install pyinstaller
    pushd $WORK_DIR
    rm -rf dist
    pyinstaller --optimize 2 --noupx $REPO_DIR/wrappers/windows/clang.py
    pyinstaller -y clang.spec
    pyinstaller --optimize 2 --noupx $REPO_DIR/wrappers/windows/rust.py
    pyinstaller -y rust.spec
    popd

    pushd $MOZBUILD_DIR/clang/bin
    mv clang.exe clang.real.exe
    powershell del clang++.exe
    powershell del clang-cl.exe
    cp -r $WORK_DIR/dist/clang/. ./
    cp clang.exe clang++.exe
    cp clang.exe clang-cl.exe
    popd

    rustup default nightly-2025-02-17

    pushd $(dirname $(~/.cargo/bin/rustup which rustc))
    mv rustc.exe rustc.real.exe
    cp -r $WORK_DIR/dist/rust/. ./
    mv rust.exe rustc.exe
    popd
    ;;
  android)
    # Clone microG
    MICROG_VERSION=v0.3.11.250932
    git clone -b $MICROG_VERSION --depth 1 --single-branch --no-tags https://github.com/microg/GmsCore microg

    # Config gradle
    mkdir -p ~/.gradle
    echo "org.gradle.daemon=false" > ~/.gradle/gradle.properties

    # Bootstrap building environments
    yes 'N' | python3 mach --no-interactive bootstrap --application-choice mobile_android

    # Setup AVD
    mkdir -p ~/.config/"Android Open Source Project"
    echo -e "[General]\nshowNestedWarning=false\nshowGpuWarning=false" > ~/.config/"Android Open Source Project"/Emulator.conf
    yes 'N' | python3 mach python python/mozboot/mozboot/android.py --avd-manifest=$REPO_DIR/android31-x86_64.json --no-interactive

    # Setup libndk for AVD
    # sudo apt install -y udev
    # sudo groupadd -r kvm || true
    # sudo gpasswd -a $(whoami) kvm || true
    # ADB="$MOZBUILD_DIR/android-sdk-linux/platform-tools/adb -s emulator-5554"
    # git clone --depth 1 --single-branch --no-tags https://github.com/HeXis-YS/vendor_google_proprietary_ndk_translation-prebuilt /tmp/libndk
    # ANDROID_EMULATOR_HOME=$MOZBUILD_DIR/android-device $MOZBUILD_DIR/android-sdk-linux/emulator/emulator \
    #   -avd mozemulator-android31-x86_64 -skip-adb-auth -selinux permissive -memory 8192 -cores 4 -skin 1280x960 -writable-system -no-audio -no-window -no-boot-anim \
    #   -qemu -enable-kvm -cpu host -smp cores=4 &
    # $ADB wait-for-device root
    # $ADB remount || true
    # $ADB reboot
    # $ADB wait-for-device root
    # $ADB remount
    # $ADB push /tmp/libndk/prebuilts/. /system/
    # $ADB reboot
    # $ADB wait-for-device emu kill
    # wait
    # rm -rf /tmp/libndk

    # Setup clang wrapper
    pushd $MOZBUILD_DIR/clang/bin
    install -m0755 $REPO_DIR/wrappers/android/clang.py clang.py
    mv clang clang.real
    ln -sf clang.py clang
    # ln -sf clang.py clang++
    popd

    # Setup rust wrapper
    source $HOME/.cargo/env
    rustup default nightly-2025-02-17
    rustup target add aarch64-linux-android
    pushd $(dirname $(~/.cargo/bin/rustup which rustc))
    [ ! -f rustc.real ] && mv rustc rustc.real
    install -m0755 $REPO_DIR/wrappers/android/rust.py rust.py
    ln -sf rust.py rustc
    popd
    ;;
esac

popd
