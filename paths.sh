#!/bin/bash
readonly REPO_DIR="$(dirname "$(realpath "$0")")"
readonly WORK_DIR="$(dirname "$(realpath "$0")")"
readonly PATCHES_DIR="${WORK_DIR}/patches"
readonly MOZCONFIGS_DIR="${WORK_DIR}/mozconfigs"
readonly MOZBUILD_DIR="$(realpath ~/.mozbuild)"
if [[ "$(uname)" == "Linux" ]]; then
  export PATH="${WORK_DIR}/venv/bin:${PATH}"
fi