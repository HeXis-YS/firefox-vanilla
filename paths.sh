#!/bin/bash
readonly REPO_DIR="$(dirname "$(realpath "$0")")"
readonly WORK_DIR="$(dirname "$(realpath "$0")")"
readonly MOZBUILD_DIR="$(realpath ~/.mozbuild)"
export PATH="${WORK_DIR}/firefox:${PATH}"
if [[ "$(uname)" == "Linux" ]]; then
  export PATH="${WORK_DIR}/venv/bin:${PATH}"
  export ANDROID_HOME=$(realpath ${MOZBUILD_DIR}/android-sdk-linux)
  export JAVA_HOME=$(realpath ${MOZBUILD_DIR}/jdk/jdk-*)
  export GECKO_PATH=$(realpath .)
fi