#!/usr/bin/env bash
# On-device frame time benchmark (profile mode). Usage: tool/perf.sh <device-id> [device-name]
# e.g. tool/perf.sh 00008110-XXXX iphone13; PERF_MAX_P90_MS=16 tool/perf.sh emulator-5554 pixel6
set -euo pipefail
cd "$(dirname "$0")/.."
device="${1:?find the device id with flutter devices}"
PERF_LABEL="${2:-$device}" flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/chart_perf_test.dart \
  -d "$device"
