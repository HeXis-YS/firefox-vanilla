#!/bin/bash
readonly REPO_DIR="$(realpath "$0")"
readonly WORK_DIR="$(realpath "$0")"
if [[ "$(uname)" == "Linux" ]]; then
  export PATH="${WORK_DIR}/venv/bin:${PATH}"
fi