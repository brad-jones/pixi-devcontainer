#!/usr/bin/env bash
set -euo pipefail
source dev-container-features-test-lib

check "pixi init" pixi init
check "pixi add" pixi add rattler-build
check "pixi run" pixi run rattler-build -V

reportResults
