#!/bin/bash
set -e

# 定义工作目录为脚本所在目录的上一级的 overseas-vps/mosdns/rules
WORKDIR=$(dirname "$0")/../overseas-vps/mosdns/rules
echo "工作目录: $WORKDIR"

# 确保工作目录存在
mkdir -p $WORKDIR

# 定义规则来源
# 直连列表
direct_list=(
  "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
  "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/apple-cn.txt"
  "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/google-cn.txt"
)

# 代理列表
proxy_list=(
  "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt"
  "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt"
  "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt"
)

# CN IP库
cn_ip_url="https://raw.githubusercontent.com/Hackl0us/GeoIP2-CN/release/CN-ip-cidr.txt"

# 定义临时文件和最终文件
direct_tmp="$WORKDIR/direct.tmp"
proxy_tmp="$WORKDIR/proxy.tmp"
direct_final="$WORKDIR/direct-list.txt"
proxy_final="$WORKDIR/proxy-list.txt"
cn_ip_final="$WORKDIR/cn-ip-cidr.txt"

# 清理临时文件
rm -f "$direct_tmp" "$proxy_tmp"

echo "开始下载直连域名规则..."
for url in "${direct_list[@]}"; do
  echo "下载: $url"
  curl -L --connect-timeout 10 --retry 3 "$url" | grep -v -E "^#|^$" >> "$direct_tmp" || echo "下载失败: $url"
done

echo "开始下载代理域名规则..."
for url in "${proxy_list[@]}"; do
  echo "下载: $url"
  curl -L --connect-timeout 10 --retry 3 "$url" | grep -v -E "^#|^$" >> "$proxy_tmp" || echo "下载失败: $url"
done

echo "开始下载CN IP库..."
curl -L --connect-timeout 10 --retry 3 "$cn_ip_url" | grep -v -E "^#|^$" > "$cn_ip_final" || echo "下载CN IP库失败"

echo "合并与去重规则..."
# 合并用户自定义规则和下载的规则，然后排序去重
# 用户自定义规则 force-cn.txt 和 force-nocn.txt 需要预先存在
cat "$WORKDIR/force-cn.txt" "$direct_tmp" 2>/dev/null | sort -u > "$direct_final"
cat "$WORKDIR/force-nocn.txt" "$proxy_tmp" 2>/dev/null | sort -u > "$proxy_final"

# 清理临时文件
rm -f "$direct_tmp" "$proxy_tmp"

echo "规则更新完成。"
echo "直连域名列表: $direct_final"
echo "代理域名列表: $proxy_final"
echo "CN IP库: $cn_ip_final" 