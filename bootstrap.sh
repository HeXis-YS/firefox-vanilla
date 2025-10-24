#!/usr/bin/bash -e

if [[ $1 != "windows" && $1 != "android" ]]; then
    exit 1
fi

source $(dirname $0)/paths.sh

GIT_BRANCH="FIREFOX_140_2_0esr_RELEASE"

if [[ $(uname) == "Linux" ]]; then
  sudo apt update
  sudo apt install -y python3 python3-pip python3-venv git libx11-6 procps
fi

cd $WORK_DIR
git clone --branch=$GIT_BRANCH --depth 1 --single-branch --no-tags https://github.com/HeXis-YS/firefox

pushd firefox
cp -vf $REPO_DIR/mozconfigs/$1 $GECKO_PATH/mozconfig

case $1 in
  windows)
    python3 mach --no-interactive bootstrap --application-choice browser
    hg clone --stream --config format.generaldelta=true --config extensions.fsmonitor= https://hg-edge.mozilla.org/l10n-central/zh-CN $MOZBUILD_DIR/l10n-central/zh-CN
    watchman shutdown-server

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
    mkdir -p ~/.gradle
    echo "org.gradle.daemon=false" > ~/.gradle/gradle.properties
    yes 'N' | python3 mach --no-interactive bootstrap --application-choice mobile_android

    ADB="$MOZBUILD_DIR/android-sdk-linux/platform-tools/adb -s emulator-5554"
    mkdir -p ~/.config/"Android Open Source Project"
    echo -e "[General]\nshowNestedWarning=false\nshowGpuWarning=false" > ~/.config/"Android Open Source Project"/Emulator.conf
    yes 'N' | python3 mach python python/mozboot/mozboot/android.py --avd-manifest=$REPO_DIR/android31-x86_64.json --no-interactive

    # sudo apt install -y udev
    # sudo groupadd -r kvm || true
    # sudo gpasswd -a $(whoami) kvm || true
    git clone --depth 1 --single-branch --no-tags https://github.com/HeXis-YS/vendor_google_proprietary_ndk_translation-prebuilt /tmp/libndk
    ANDROID_EMULATOR_HOME=$MOZBUILD_DIR/android-device $MOZBUILD_DIR/android-sdk-linux/emulator/emulator \
      -avd mozemulator-android31-x86_64 -skip-adb-auth -selinux permissive -memory 8192 -cores 4 -skin 1280x960 -writable-system -no-snapstorage -no-audio -no-window -no-boot-anim -qemu -cpu host -smp cores=4 &
    $ADB wait-for-device root
    $ADB remount || true
    $ADB reboot
    $ADB wait-for-device root
    $ADB remount
    $ADB push /tmp/libndk/prebuilts/. /system/
    $ADB reboot
    $ADB wait-for-device emu kill
    wait
    rm -rf /tmp/libndk

    mv $MOZBUILD_DIR/clang/bin/clang $MOZBUILD_DIR/clang/bin/clang.real
    install -m755 $REPO_DIR/wrappers/android/clang.py $MOZBUILD_DIR/clang/bin/clang

    source $HOME/.cargo/env
    rustup default nightly-2025-02-17
    rustup target add aarch64-linux-android
    pushd $(dirname $(~/.cargo/bin/rustup which rustc))
    mv rustc rustc.real
    install -m755 $REPO_DIR/wrappers/android/rust.py rustc
    popd
    ;;
esac

popd
