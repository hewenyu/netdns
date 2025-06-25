#!/bin/bash
set -e

# 检查是否提供了足够的参数
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "错误: 请提供两个域名参数。"
  echo "用法: $0 <你的海外域名> <你的国内DoH域名>"
  echo "示例: $0 my-overseas-dns.com dns.my-cn-server.com"
  exit 1
fi

OVERSEAS_DOMAIN=$1
CN_DOH_DOMAIN=$2

# 定义配置文件路径
OPENRESTY_CONFIG="./openresty/conf.d/default.conf"
MOSDNS_CONFIG="./mosdns/config.yaml"
COMPOSE_FILE="./docker-compose.yml"

# 定义占位符
OPENRESTY_PLACEHOLDER="YOUR_OVERSEAS_DOMAIN.COM"
MOSDNS_PLACEHOLDER="dns.your-cn-domain.com"

# 检查配置文件是否存在
if [ ! -f "$OPENRESTY_CONFIG" ] || [ ! -f "$MOSDNS_CONFIG" ]; then
  echo "错误: 配置文件未找到。"
  echo "请确保您在 'overseas-vps' 目录下运行此脚本。"
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "错误: 配置文件 '$COMPOSE_FILE' 未找到。"
  echo "请确保您在 'overseas-vps' 目录下运行此脚本。"
  exit 1
fi

echo "正在更新 OpenResty 域名为: $OVERSEAS_DOMAIN"
sed -i.bak "s/$OPENRESTY_PLACEHOLDER/$OVERSEAS_DOMAIN/g" "$OPENRESTY_CONFIG"

echo "正在更新 MosDNS 的国内上游DoH域名为: $CN_DOH_DOMAIN"
sed -i.bak "s/$MOSDNS_PLACEHOLDER/$CN_DOH_DOMAIN/g" "$MOSDNS_CONFIG"

echo "正在更新 Compose 文件中的域名为: $OVERSEAS_DOMAIN"
sed -i.bak "s/$OVERSEAS_PLACEHOLDER/$OVERSEAS_DOMAIN/g" "$COMPOSE_FILE"


echo "域名更新完成。"
echo "已创建备份文件 '*.bak'。"
echo "请检查 '$OPENRESTY_CONFIG' 和 '$MOSDNS_CONFIG' 的内容确认修改是否正确。" 
echo "请检查 '$COMPOSE_FILE' 的内容确认修改是否正确。" 