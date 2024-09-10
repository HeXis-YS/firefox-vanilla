#!/bin/bash
source "$(dirname "$0")/paths.sh"

case "$1" in
    windows|linux)
        install -v $REPO_DIR/mozconfig-$1 $WORK_DIR/firefox/mozconfig
        pushd $WORK_DIR/firefox
        python mach --no-interactive bootstrap --application-choice browser
        popd
        ;;
    android)
        install -v $REPO_DIR/mozconfig-android $WORK_DIR/firefox/mozconfig
        pushd $WORK_DIR/firefox
        python mach --no-interactive bootstrap --application-choice mobile_android
        popd
        ;;
    *)
        exit 1
    ;;
esac



pushd $WORK_DIR/firefox
python mach configure
python mach build
popd