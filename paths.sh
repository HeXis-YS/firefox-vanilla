#!/bin/bash
readonly REPO_DIR="$(dirname "$(realpath "$0")")"
readonly WORK_DIR="$(dirname "$(realpath "$0")")"
if [[ "$(uname)" == "Linux" ]]; then
  export PATH="${WORK_DIR}/venv/bin:${PATH}"
fi