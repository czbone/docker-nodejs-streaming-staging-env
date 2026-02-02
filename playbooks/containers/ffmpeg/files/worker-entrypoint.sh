#!/bin/bash
set -e

echo "Starting FFmpeg worker initialization..."

# アプリケーションディレクトリに移動
cd /app

# パッケージのインストール
echo "Installing packages..."
pnpm install

# ワーカープロセスを起動
echo "Starting worker process..."
exec pnpm start
