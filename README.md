# Docker環境構築（Astro動画配信システム）

Vagrantを使用してUbuntu 24.04上にDocker環境を自動構築するプロジェクトです。
Ansibleを使用して必要なソフトウェアのインストールと設定を行い、GitHubから取得したAstroベースの動画配信システム（[astro-streaming-sample](https://github.com/czbone/astro-streaming-sample)）を自動的にビルド・実行するための実行環境を構築します。

## 環境構成

- **OS**: Ubuntu 24.04 (bento/ubuntu-24.04)
- **Docker**: geerlingguy.docker ロールによるインストール
- **タイムゾーン**: Asia/Tokyo

### Dockerコンテナ構成

| コンテナ | バージョン | 説明 |
|---------|------------|------|
| Node.js | v24.0.0 (alpine) | アプリケーションサーバー（Astro SSR） |
| Nginx | 1.28.1 (alpine) | リバースプロキシ/Webサーバー（HLSファイル配信） |
| FFmpeg | 8.0.1 | 動画のHLS変換処理用コンテナ |
| Redis | 7.4.2 | コンテナ間連携用キャッシュサーバー |
| Certbot | 5.2.2 | Let's Encrypt証明書取得用（オプション） |

## 前提条件

- [VirtualBox](https://www.virtualbox.org/) がインストールされていること
- [Vagrant](https://www.vagrantup.com/) がインストールされていること
- 十分なメモリ（最低2GB）と空きディスク容量があること

## ディレクトリ構成

```
.
├── README.md             # このファイル
├── Vagrantfile           # Vagrant設定ファイル
└── playbooks/            # Ansibleプレイブック
    ├── main.yml              # メインプレイブック
    ├── requirements.yml      # 必要なロールの定義
    ├── vars/                 # 変数定義
    │   └── main.yml              # メイン変数ファイル
    ├── tasks/                # タスク定義
    │   ├── japanese.yml          # 日本語環境設定
    │   ├── redis.yml             # Redisコンテナ構築
    │   ├── ffmpeg.yml            # FFmpegコンテナ構築
    │   ├── nginx.yml             # Nginxコンテナ構築
    │   ├── certbot.yml           # Certbotコンテナ構築
    │   ├── nodejs.yml            # Node.jsコンテナ構築
    │   └── app.yml               # アプリケーションデプロイ
    └── containers/           # コンテナ設定
        ├── nginx/                # Nginx用設定ファイル等
        ├── nodejs/               # Node.js用Dockerfile等
        ├── redis/                # Redis用Dockerfile等
        └── certbot/              # Certbot用設定ファイル等
```

## IPアドレス設定

仮想マシンには固定IPアドレス `192.168.33.10` が設定されます。
必要に応じて `Vagrantfile` の `config.vm.network` の設定を変更してください。

## 起動手順

1. リポジトリをクローンする
2. 以下のコマンドを実行してVirtualBox上に環境を構築

```bash
vagrant up
```

## 接続方法

環境構築後、以下のいずれかの方法で仮想マシンに接続できます。

1. Vagrantから接続:
```bash
vagrant ssh
```

2. SSHで直接接続:
```bash
ssh vagrant@192.168.33.10
```
※デフォルトパスワード: vagrant

### rootユーザーへの切り替え
接続後、以下のコマンドでrootユーザーに切り替えることができます。
```bash
sudo su -
```

## Dockerコンテナの確認

環境構築後、仮想マシン内で以下のコマンドでコンテナの状態を確認できます。

```bash
docker ps                    # 実行中のコンテナ一覧
docker logs nodejs           # Node.jsコンテナのログ
docker logs nginx            # Nginxコンテナのログ
docker logs ffmpeg-worker    # FFmpegコンテナのログ
docker logs redis            # Redisコンテナのログ
docker logs certbot          # Certbotコンテナのログ（有効な場合）
```

## アプリケーション機能

この環境では、[astro-streaming-sample](https://github.com/czbone/astro-streaming-sample) がデプロイされ、以下の機能を提供します：

- 📤 **動画アップロード**: MP4形式の動画ファイルをアップロード（最大500MB）
- 🔄 **自動HLS変換**: FFmpegを使用してHLS形式に自動変換
- 📺 **動画一覧**: アップロードされた動画の一覧表示
- 🎬 **動画視聴**: HLS.jsを使用した高品質なストリーミング再生

### 技術スタック

- [Astro](https://astro.build/) - コンテンツ駆動型Webサイトのためのフレームワーク
- [React](https://react.dev/) - UIコンポーネントライブラリ
- [TailwindCSS v4](https://tailwindcss.com/) - ユーティリティファーストCSSフレームワーク
- [Flowbite](https://flowbite.com/) - TailwindCSS用UIコンポーネント
- [hls.js](https://github.com/video-dev/hls.js/) - HLSストリーミング再生ライブラリ

## カスタマイズ

- `playbooks/vars/main.yml` を編集することで、コンテナ名やアプリケーションリポジトリ設定を変更できます
- `playbooks/main.yml` を編集することで、追加のパッケージやタスクを追加できます
- `Vagrantfile` の `vb.memory` を編集して、仮想マシンのメモリ割り当てを変更できます
- `playbooks/main.yml` の `certbot_enabled` を `true` に設定することで、Let's Encrypt証明書の自動取得を有効化できます

## データディレクトリ

動画ファイルは以下のディレクトリに保存されます：

- `/docker/data/original/`: アップロードされた元のMP4ファイル
- `/docker/data/hls/`: FFmpegで変換されたHLSファイル（各動画はID名のディレクトリに保存）

## HLS配信について

- HLSファイルはNginxコンテナ経由で配信されます
- ブラウザではhls.jsを使用して再生されます（SafariはネイティブHLSサポートを使用）
- 動画は10秒単位のセグメントに分割され、ネットワーク状況に応じて最適な解像度が選択されます

## アプリケーションのカスタマイズ

別のアプリケーションを使用する場合は `playbooks/vars/main.yml` の `app_repo_*` 変数を変更してください。

## トラブルシューティング

### ネットワーク接続の問題
ネットワーク設定に問題が発生した場合は、`Vagrantfile` の IPアドレスを
使用環境に合わせて変更してください。

### 仮想マシンの起動に失敗する場合
VirtualBoxの設定や競合を確認し、必要に応じてVirtualBoxを再起動してください。

### プロビジョニングを再実行する場合
```bash
vagrant provision
```
