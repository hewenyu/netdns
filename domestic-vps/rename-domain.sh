#!/bin/bash
set -e

# 检查是否提供了域名参数
if [ -z "$1" ]; then
  echo "错误: 请提供您的域名作为第一个参数。"
  echo "用法: $0 your-cn-domain.com"
  exit 1
fi

DOMAIN=$1
CONFIG_FILE="./openresty/conf.d/default.conf"
COMPOSE_FILE="./docker-compose.yml"
PLACEHOLDER="YOUR_CN_DOMAIN.COM"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
  echo "错误: 配置文件 '$CONFIG_FILE' 未找到。"
  echo "请确保您在 'domestic-vps' 目录下运行此脚本。"
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "错误: 配置文件 '$COMPOSE_FILE' 未找到。"
  echo "请确保您在 'domestic-vps' 目录下运行此脚本。"
  exit 1
fi

echo "正在将配置文件中的域名更新为: $DOMAIN..."

# 使用sed替换占位符
# 注意: 使用-i.bak创建备份，以防万一
sed -i.bak "s/$PLACEHOLDER/$DOMAIN/g" "$CONFIG_FILE"
sed -i.bak "s/$PLACEHOLDER/$DOMAIN/g" "$COMPOSE_FILE"

echo "域名更新完成。"
echo "已创建备份文件 '$CONFIG_FILE.bak'。"
echo "请检查 '$CONFIG_FILE' 的内容确认修改是否正确。" 
echo "请检查 '$COMPOSE_FILE' 的内容确认修改是否正确。" 