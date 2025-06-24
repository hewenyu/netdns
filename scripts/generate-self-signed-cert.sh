#!/bin/bash
set -e

# 此脚本用于为Nginx/OpenResty的默认服务器块生成一个自签名SSL证书。
# 这个证书用于捕获所有未匹配到server_name的HTTPS请求并返回404，
# 从而防止IP直连和恶意域名绑定。

# 定义输出目录
DOMESTIC_CERT_DIR="$(dirname "$0")/../domestic-vps/openresty/ssl/default"
OVERSEAS_CERT_DIR="$(dirname "$0")/../overseas-vps/openresty/ssl/default"

# 确保输出目录存在
mkdir -p "$DOMESTIC_CERT_DIR"
mkdir -p "$OVERSEAS_CERT_DIR"

# 定义证书和密钥路径
DOMESTIC_KEY="$DOMESTIC_CERT_DIR/snakeoil.key"
DOMESTIC_CERT="$DOMESTIC_CERT_DIR/snakeoil.pem"
OVERSEAS_KEY="$OVERSEAS_CERT_DIR/snakeoil.key"
OVERSEAS_CERT="$OVERSEAS_CERT_DIR/snakeoil.pem"

# 检查证书是否已存在
if [ -f "$DOMESTIC_CERT" ] && [ -f "$OVERSEAS_CERT" ]; then
  echo "自签名证书已存在，无需重新生成。"
  exit 0
fi

echo "正在生成自签名证书 (snakeoil)..."

# 使用openssl生成证书和私钥
openssl req -x509 -newkey rsa:4096 -keyout snakeoil.key -out snakeoil.pem \
  -days 3650 -nodes -subj "/C=US/ST=Denial/L=Nowhere/O=Net/CN=localhost"

echo "证书生成成功。"

# 将证书和密钥复制到目标目录
echo "正在复制证书到 domestic-vps 和 overseas-vps 目录..."
cp snakeoil.key "$DOMESTIC_KEY"
cp snakeoil.pem "$DOMESTIC_CERT"
cp snakeoil.key "$OVERSEAS_KEY"
cp snakeoil.pem "$OVERSEAS_CERT"

# 清理临时文件
rm snakeoil.key snakeoil.pem

echo "自签名证书已成功安装到所有目标位置。" 