#!/usr/bin/env bash
set -euo pipefail
source dev-container-features-test-lib

check "CONDA_PREFIX" sh -c 'env | grep CONDA_PREFIX'
check "go-task" task --version

reportResults
