# サーバのホスト名
export SERVER_1="c1"
export SERVER_2="c2"
export SERVER_3="c3"
export BENCH_SERVER="b"

# APサーバの一覧
export APP_SERVERS=($SERVER_1)
# DBサーバの一覧
export DB_SERVERS=($SERVER_1)
# Redisサーバの一覧
export REDIS_SERVERS=($SERVER_1)
# 全サーバの一覧
export ALL_SERVERS=($SERVER_1 $SERVER_2 $SERVER_3)
# ユーザ名
export ISUCON_USER='isucon'
# グループ名
export ISUCON_GROUP='isucon'
# gitのルートディレクトリ
export REPO_DIR="/home/$ISUCON_USER"
# 実行プログラムが格納されているディレクトリ
export PROJECT_DIR="$REPO_DIR/webapp/go"
# プログラム名
export PROGRAM_NAME="isucondition"
# Systemd サービス名
export PROGRAM_SERVICE_NAME="isucondition.go.service"
# Systemd サービス名(バッチ)
export BATCH_SERVICE_NAME="isushintaro-batch.service"

# ALPのログを集約するための設定
export ALP_AGGREGATE_REGEX="^/api/condition/[0-9a-z-]+$,^/api/isu/[0-9a-z-]+/icon$,^/api/isu/[0-9a-z-]+/graph$,^/api/isu/[0-9a-z-]+$,^/isu/[0-9a-z-]+/graph$,^/isu/[0-9a-z-]+$,^/isu/[0-9a-z-]+/condition$"

### ここから下は基本的に設定不要

# バッチログを格納するディレクトリ TODO パスの確定
export BATCH_LOG_DIR="/tmp/log"
# バッチログファイル名 TODO 名前の確定
export BATCH_LOG_NAME="batch.log"
# バッチログのフルパス
export BATCH_LOG="$BATCH_LOG_DIR/$BATCH_LOG_NAME"
# ログを格納するS3バケット
export LOG_S3_BUCKET='isushintaro-isulog'
# 環境設定が格納されたファイル
export ENV_SH_FILE="$REPO_DIR/env.sh"
# 環境設定が格納されたファイル
export ENV_BATCH_SH_FILE="$REPO_DIR/env_batch.sh"

# ベンチマークのコードを格納するディレクトリ（本番では不要）
export BENCH_DIR="$REPO_DIR/bench"
# ベンチ実行時、Webアクセスを受け取るNginxのホスト名（本番では不要）
export TARGET_HOST='isucondition-1.t.isucon.dev'

export PPROF_SECONDS=80
export PPROF_HOST="localhost:3101"
export APPLICATION_HOST="localhost:3000"
