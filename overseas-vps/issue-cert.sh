#!/bin/bash
set -e

# 检查是否提供了域名参数
if [ -z "$1" ]; then
  echo "错误: 请提供您的域名作为第一个参数。"
  echo "用法: $0 your-overseas-domain.com"
  exit 1
fi

DOMAIN=$1
SSL_PATH="$(pwd)/openresty/ssl"
ACME_DATA_PATH="$(pwd)/acme.sh"
WEBROOT_PATH="$(pwd)/certbot/www"

# 检查 docker-compose.yml 是否存在，以确认在正确的目录下
if [ ! -f "docker-compose.yml" ]; then
  echo "错误: 'docker-compose.yml' 未找到。"
  echo "请确保您在 'overseas-vps' 目录下运行此脚本。"
  exit 1
fi

# 确保相关目录存在
mkdir -p "$SSL_PATH"
mkdir -p "$ACME_DATA_PATH"
mkdir -p "$WEBROOT_PATH"

echo "正在为域名 '$DOMAIN' 申请证书..."
echo "证书将安装到: $SSL_PATH"
echo "ACME数据将保存到: $ACME_DATA_PATH"

# 运行 acme.sh 容器来申请证书
docker run --rm -it \
  -v "$ACME_DATA_PATH":/acme.sh \
  -v "$WEBROOT_PATH":/webroot \
  neilpang/acme.sh --issue --webroot /webroot -d "$DOMAIN" --server letsencrypt

# 安装证书到指定目录
echo "正在安装证书到 $SSL_PATH ..."
docker run --rm -it \
  -v "$ACME_DATA_PATH":/acme.sh \
  -v "$SSL_PATH":/certs \
  neilpang/acme.sh --install-cert -d "$DOMAIN" \
  --cert-file      /certs/cert.pem \
  --key-file       /certs/privkey.pem \
  --fullchain-file /certs/fullchain.pem

# 赋予证书正确的权限
chmod 644 "$SSL_PATH"/*

echo "证书申请和安装完成！"
echo "acme.sh 将会自动在容器数据卷中创建续期任务。"
echo "请执行 'docker-compose restart openresty' 来加载新证书。" 