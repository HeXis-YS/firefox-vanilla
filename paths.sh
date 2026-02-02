#!/usr/bin/bash
_REPO_DIR="$(dirname "$(realpath "$0")")"
_WORK_DIR="$(pwd)"
_MOZBUILD_DIR="$(realpath ~/.mozbuild)"
export GECKO_PATH="$_WORK_DIR/firefox"

[ -d $_MOZBUILD_DIR/clang/bin ] && export PATH="$_MOZBUILD_DIR/clang/bin:$PATH"
[ -d $_MOZBUILD_DIR/sccache ] && export PATH="$_MOZBUILD_DIR/sccache:$PATH"

if [[ "$(uname)" == "Linux" ]]; then
  _TMP_DIR=/tmp/firefox-vanilla
  export _CACHE_DIR=$_WORK_DIR/cache
  mkdir -p $_TMP_DIR $_CACHE_DIR
  export PATH="$_WORK_DIR/venv/bin:$PATH"
  export ANDROID_HOME="$_MOZBUILD_DIR/android-sdk-linux"
  unset ANDROID_SDK_ROOT
  if [ -n $JAVA_HOME_17_X64 ]; then
    export JAVA_HOME=$JAVA_HOME_17_X64
  else
    export JAVA_HOME=$_MOZBUILD_DIR/jdk/jdk-17.0.15+6
  fi
  export GRADLE_OPTS="-Dorg.gradle.daemon=false"
fi
