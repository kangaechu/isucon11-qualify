#!/bin/bash

set -ex
source /home/isucon/env_bench.sh

# バッチログのクリア(存在しない場合は空ファイル作成)
set +e
if [ -e $BATCH_LOG ]; then
  echo "$BATCH_LOGをクリアします"
  sudo truncate --size 0 $BATCH_LOG
  echo "$BATCH_LOGをクリアしました"
else
  echo "$BATCH_LOGが存在しません"
  mkdir -p $BATCH_LOG_DIR
  touch $BATCH_LOG
  echo "空の$BATCH_LOGを作成しました"
fi

# バッチプロセスがサービス登録されているか確認
HOST_NAME=$(hostname)
sudo systemctl list-unit-files | grep "$BATCH_SERVICE_NAME"
if [ $? -eq 0 ]; then
  # バッチプロセスの自動起動が有効か確認
  sudo systemctl is-enabled "$BATCH_SERVICE_NAME"
  if [ $? -eq 0 ]; then
    # バッチプロセスの再起動
    echo "$HOST_NAME の $BATCH_SERVICE_NAMEを再起動します"
    sudo systemctl restart "$BATCH_SERVICE_NAME"
    echo "$HOST_NAME の $BATCH_SERVICE_NAMEを再起動しました"
  else
    echo "$HOST_NAME の $BATCH_SERVICE_NAMEは無効になっています"
  fi
else
  echo "$HOST_NAME の $BATCH_SERVICE_NAMEはサービス登録されていません"
fi
set -e
