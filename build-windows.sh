#!/bin/bash
source "$(dirname "$0")/paths.sh"

case "$1" in
    windows)
        install -v $REPO_DIR/mozconfig-windows $WORK_DIR/firefox/mozconfig
        ;;
    linux)
        install -v $REPO_DIR/mozconfig-linux $WORK_DIR/firefox/mozconfig
        ;;
    android)
        install -v $REPO_DIR/mozconfig-android $WORK_DIR/firefox/mozconfig
        ;;
    *)
        exit 1
    ;;
esac



pushd $WORK_DIR/firefox
python mach --no-interactive bootstrap --application-choice browser
python mach configure
python mach build
popd