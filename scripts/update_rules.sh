#!/bin/bash
set -e

# 定义工作目录为脚本所在目录的上一级的 overseas-vps/mosdns/rules
WORKDIR=$(dirname "$0")/../overseas-vps/mosdns/rules
echo "工作目录: $WORKDIR"

# 确保工作目录存在
mkdir -p "$WORKDIR"

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
force_cn_path="$WORKDIR/force-cn.txt"
force_nocn_path="$WORKDIR/force-nocn.txt"

# 清理可能存在的旧文件
rm -f "$direct_tmp" "$proxy_tmp"

# 下载函数
download() {
  local url=$1
  local output=$2
  echo "开始下载: $url"
  if ! curl -L --connect-timeout 10 --retry 3 -sS "$url" >> "$output"; then
    echo "下载失败: $url" >&2
    exit 1
  fi
}

# 并行下载
pids=""

echo "开始并行下载直连域名规则..."
for url in "${direct_list[@]}"; do
  download "$url" "$direct_tmp" &
  pids="$pids $!"
done

echo "开始并行下载代理域名规则..."
for url in "${proxy_list[@]}"; do
  download "$url" "$proxy_tmp" &
  pids="$pids $!"
done

echo "开始下载CN IP库..."
download "$cn_ip_url" "$cn_ip_final.tmp" &
pids="$pids $!"

# 等待所有后台下载任务完成
for pid in $pids; do
  if ! wait "$pid"; then
    echo "一个或多个下载任务失败。" >&2
    # 清理临时文件
    rm -f "$direct_tmp" "$proxy_tmp" "$cn_ip_final.tmp"
    exit 1
  fi
done
echo "所有规则文件下载成功。"

echo "处理和合并规则..."

# 处理下载的规则文件，移除注释和空行
process_file() {
    local input=$1
    local output=$2
    grep -v -E "^#|^$" "$input" > "$output"
    rm "$input"
}

process_file "$direct_tmp" "$direct_tmp.processed" &
process_file "$proxy_tmp" "$proxy_tmp.processed" &
process_file "$cn_ip_final.tmp" "$cn_ip_final" &
wait

# 合并用户自定义规则和下载的规则，然后排序去重
{
    if [[ -f "$force_cn_path" ]]; then cat "$force_cn_path"; fi
    cat "$direct_tmp.processed"
} | sort -u > "$direct_final"

{
    if [[ -f "$force_nocn_path" ]]; then cat "$force_nocn_path"; fi
    cat "$proxy_tmp.processed"
} | sort -u > "$proxy_final"


# 清理临时文件
rm -f "$direct_tmp.processed" "$proxy_tmp.processed"

echo "规则更新完成。"
echo "直连域名列表: $direct_final"
echo "代理域名列表: $proxy_final"
echo "CN IP库: $cn_ip_final" 