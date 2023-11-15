#!/bin/bash

export PATH=$PATH:$HOME/local/go/bin

source /home/isucon/env_bench.sh

set -ex
cd "$REPO_DIR"
git pull

cd "$PROJECT_DIR"
go build -o "$PROGRAM_NAME"

sudo systemctl restart "$PROGRAM_SERVICE_NAME"
