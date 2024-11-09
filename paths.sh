#!/bin/bash
REPO_DIR="$(dirname "$(realpath "$0")")"
WORK_DIR="$(pwd)"
PATCHES_DIR="${WORK_DIR}/patches"
MOZBUILD_DIR="$(realpath ~/.mozbuild)"
export GECKO_PATH="${WORK_DIR}/firefox"

export PATH="${MOZBUILD_DIR}/sccache:${PATH}"

if [[ "$(uname)" == "Linux" ]]; then
  export PATH="${WORK_DIR}/venv/bin:${PATH}"
  export ANDROID_HOME="${MOZBUILD_DIR}/android-sdk-linux"
  export JAVA_HOME="${MOZBUILD_DIR}/jdk/jdk"
fi

export GRADLE_OPTS=-Dorg.gradle.daemon=false