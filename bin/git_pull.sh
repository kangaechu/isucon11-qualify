#!/bin/bash

source /home/isucon/env_bench.sh

set -ex
cd "${REPO_DIR}"

# リモートの最新の状態を取り込む
git fetch origin main

# リセットする
git reset --hard origin/main
