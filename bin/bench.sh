#!/bin/bash

set -ex

source /home/isucon/env_bench.sh

# リモートのコードとの差分を確認
function check_diff() {
  git switch main
  git fetch origin main
  bench_sh_updates=0
  # bin/bench.shが差分に含まれていないか確認
  git diff main origin/main --name-only | grep bin/bench.sh && bench_sh_updates=1
  git reset --hard origin/main
  if [[ $bench_sh_updates -ne 0 ]]; then
    echo "bench.shが最新ではありません。もう一度実行してください。"
    exit 1
  fi
}

# git pull
function git_pull() {
  for server in "${ALL_SERVERS[@]}"; do
    ssh -t $server "$REPO_DIR/bin/git_pull.sh"
  done
}

# Nginxの設定ファイルを更新
function update_nginx_settings() {
  for server in "${APP_SERVERS[@]}"; do
    ssh -t $server "$REPO_DIR/bin/update_nginx_settings.sh"
  done
}

# MySQLの設定ファイルを更新
function update_mysql_settings() {
  for server in "${DB_SERVERS[@]}"; do
    ssh -t $server "$REPO_DIR/bin/update_mysql_settings.sh"
  done
}

# Redisの設定ファイルを更新
function update_redis_settings() {
  for server in "${REDIS_SERVERS[@]}"; do
    ssh -t $server "$REPO_DIR/bin/update_redis_settings.sh"
  done
}

# Redisを初期化
function flush_redis() {
  for server in "${REDIS_SERVERS[@]}"; do
    ssh -t $server redis-cli flushdb
  done
}

# コードのビルド
function build() {
  for server in "${APP_SERVERS[@]}"; do
    ssh -t $server "$REPO_DIR/bin/build.sh"
  done
}

# Nginxログの削除
function clear_nginx_log() {
  for server in "${APP_SERVERS[@]}"; do
    ssh -t $server sudo "$REPO_DIR/bin/clear_log_nginx.sh"
  done
}

# MySQLログの削除
function clear_mysql_log() {
  for server in "${DB_SERVERS[@]}"; do
    ssh -t $server sudo "$REPO_DIR/bin/clear_log_mysql.sh"
  done
}

# バッチログの削除
function clear_batch_log() {
  for server in "${APP_SERVERS[@]}"; do
    ssh -t $server sudo "$REPO_DIR/bin/clear_log_batch.sh"
  done
}

# journalログの削除
function clear_journal_log() {
  for server in "${APP_SERVERS[@]}"; do
    ssh -t $server sudo journalctl --rotate
    ssh -t $server sudo journalctl --vacuum-time=1s
  done
}

# pprofの実行
function pprof() {
  for server in "${APP_SERVERS[@]}"; do
    # nohup実行時は標準出力・標準エラー出力を/dev/nullにリダイレクトしないと入力待ちとなるので注意
    ssh $server "$REPO_DIR/bin/pprof.sh" > /dev/null 2>&1 &
  done
}

# スコア結果のJSONからスコアをパース
# 本番では使えない
function parse_score() {
  json_file=$1
  PASS=$(cat "$json_file" | jq '.pass')
  SCORE=$(cat "$json_file" | jq '.score')
}

# ベンチの実行
function bench() {
  current_time=$(date "+%Y%m%d-%H%M%S")

  echo "----------------------------"
  echo "ベンチを実行してください"
  cd "$BENCH_DIR"
  "$BENCH_DIR"/bench -all-addresses $TARGET_HOST -target $TARGET_HOST -tls -jia-service-url http://isucondition-4.t.isucon.dev:4999
  echo "実行が終わったらスコアを入力し、enterキーを押して下さい"
  read -r SCORE

  # ログディレクトリの作成
  LOG_BASE_DIR='/tmp/log'
  LOG_DIR="$LOG_BASE_DIR/$current_time"
  LOG_S3_URL_BASE="https://$LOG_S3_BUCKET.s3.ap-northeast-1.amazonaws.com/$current_time"
  mkdir -p "$LOG_DIR"

  # Nginxログの取得・整形
  NGINX_LOG='/var/log/nginx/access.log'
  for server in "${APP_SERVERS[@]}"; do
    scp "$server:$NGINX_LOG" "$LOG_DIR"
    alp ltsv --file "$LOG_DIR/access.log" --sort=sum -r -m "$ALP_AGGREGATE_REGEX" >"$LOG_DIR/web-$server.txt"
  done

  # MySQLスロークエリの取得・整形
  DB_SLOW_LOG='/var/log/mysql/mysql-slow.log'
  for server in "${DB_SERVERS[@]}"; do
    scp "$server:$DB_SLOW_LOG" "$LOG_DIR"
    pt-query-digest "$LOG_DIR/mysql-slow.log" | cut -c 1-3000 >"$LOG_DIR/db-$server.txt"
  done

  # バッチログの取得
  for server in "${APP_SERVERS[@]}"; do
    scp "$server:$BATCH_LOG" "$LOG_DIR/web-$server-batch.txt"
  done

  # journalログの取得
  for server in "${APP_SERVERS[@]}"; do
    ssh $server -C "journalctl -u $PROGRAM_SERVICE_NAME" >"$LOG_DIR/journal-$server.txt"
  done

  # s3に転送
  aws s3 sync "$LOG_BASE_DIR" "s3://$LOG_S3_BUCKET/"

  # 実行結果のパース
  # parse_score "/tmp/score_$current_time.json"

  # Gitにタグ付け
  cd "$REPO_DIR"
  git pull
  git tag "$SCORE-$(date '+%Y%m%d-%H%M%S')"
  git push origin --tags
}

# Discordに1行メッセージ送信
function send_line_to_discord() {
  message=$1
  discord_webhook_url='https://discord.com/api/webhooks/862323960477646848/6GHpPsJRszohbmmSmVVDsFkatAzU8sP2Hpj-tUg6FNR_WeySkRmmzN5onbLtwqfcOeM4'
  curl -XPOST -H "Content-Type: application/json" $discord_webhook_url \
    -d "{\"content\":\"${message}\"}"
  sleep 1
}

# Discordに通知
function send_result_to_discord() {
  # 区切り文字を変更
  IFS_BEFORE=$IFS
  IFS=","

  # スコアとS3リンクを投稿
  send_line_to_discord "スコア: $SCORE"
  for server in "${APP_SERVERS[@]}"; do
    send_line_to_discord "- web-$server: $LOG_S3_URL_BASE/web-$server.txt"
  done
  for server in "${DB_SERVERS[@]}"; do
    send_line_to_discord "- db-$server: $LOG_S3_URL_BASE/db-$server.txt"
  done
  for server in "${APP_SERVERS[@]}"; do
    send_line_to_discord "- web-$server-batch: $LOG_S3_URL_BASE/web-$server-batch.txt"
  done
  for server in "${APP_SERVERS[@]}"; do
    send_line_to_discord "- journal-$server: $LOG_S3_URL_BASE/journal-$server.txt"
  done

  # APIの下位5件を投稿
  for server in "${APP_SERVERS[@]}"; do
    display_count=5
    header_count=3
    web_lower=$(cat "$LOG_DIR/web-$server.txt" | head -n $(expr ${display_count} + ${header_count}) | perl -pe 's/\n/\\r/g')
    message_web="web-$server:"'```'"\r$web_lower"'```'
    send_line_to_discord $message_web
  done

  # DBの下位を投稿
  for server in "${DB_SERVERS[@]}"; do
    db_lower=$(cat "$LOG_DIR/db-$server.txt" | grep -A 100 -E 'Profile' | grep -B 100 -E 'Query 1' | head -n -3 | perl -pe 's/\n/\\r/g')
    message_db="db-$server:"'```'"\r$db_lower"'```'
    send_line_to_discord $message_db
  done

  # 区切り文字を戻す
  IFS=$IFS_BEFORE
}

## main
check_diff

# git pull
git_pull

# Nginxの設定ファイルを更新
update_nginx_settings

# MySQLの設定ファイルを更新
update_mysql_settings

# Redisの設定ファイルを更新
update_redis_settings

# Redisを初期化
flush_redis

# ビルド
build

# Nginxログの削除
clear_nginx_log

# MySQLログの削除
clear_mysql_log

# バッチログの削除
clear_batch_log

# ジャーナルログの削除
clear_journal_log

# pprofのサーバーを立ち上げる
pprof

# ベンチの実行
bench

# Discordに通知
send_result_to_discord
