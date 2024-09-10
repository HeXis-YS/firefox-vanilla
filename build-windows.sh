#!/bin/bash
source "$(dirname "$0")/paths.sh"

install -v $WORK_DIR/mozconfig-windows $WORK_DIR/firefox/mozconfig

pushd $WORK_DIR/firefox
python mach --no-interactive bootstrap --application-choice browser
python mach configure
python mach build
popd