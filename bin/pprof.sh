#!/bin/bash

source /home/isucon/env_bench.sh

set -e
cd "${REPO_DIR}"

# pprofを起動
output_dir="$HOME/pprof"
mkdir -p "$output_dir"
pkill -f "go tool pprof" || echo "pprof is not launched"
nohup "${GO_BIN}/go" tool pprof -timeout=${PPROF_SECONDS} -seconds=${PPROF_SECONDS} -http="${PPROF_HOST}" "http://${APPLICATION_HOST}/debug/pprof/profile?seconds=${PPROF_SECONDS}" >"$output_dir/pprof_$(date '+%Y%m%d_%H%M%S').log" 2>&1
