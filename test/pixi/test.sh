#!/usr/bin/env bash
set -euo pipefail
source dev-container-features-test-lib

check "pixi add" pixi add rattler-build
check "pixi run" pixi run rattler-build -V
check "pixi path" rattler-build -V

reportResults
