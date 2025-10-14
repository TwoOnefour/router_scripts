#!/usr/bin/env bash
# 透明代理脚本模板
set -euo pipefail

# 可按需修改
XRAY_PORT=60080
IFACE=ens18          # 外部入口网卡
IN_SPORT=49576      # 仅匹配这个源端口进入的外部流量

# 清理旧链/跳转（可多次执行不报错）
iptables -t nat -D OUTPUT     -p tcp -m owner --uid-owner ss -j XRAY 2>/dev/null || true
iptables -t nat -D PREROUTING -i "$IFACE" -p tcp --sport "$IN_SPORT" -j XRAY 2>/dev/null || true
iptables -t nat -F XRAY 2>/dev/null || true
iptables -t nat -X XRAY 2>/dev/null || true

# 新建 XRAY 链（统一做排除与重定向）
iptables -t nat -N XRAY

# 1) 目的地址排除（回环/保留/私网等，避免无意义重定向与自环）
iptables -t nat -A XRAY -d 0.0.0.0/8      -j RETURN
iptables -t nat -A XRAY -d 10.0.0.0/8     -j RETURN
iptables -t nat -A XRAY -d 100.64.0.0/10  -j RETURN
iptables -t nat -A XRAY -d 127.0.0.0/8    -j RETURN
iptables -t nat -A XRAY -d 169.254.0.0/16 -j RETURN
iptables -t nat -A XRAY -d 172.16.0.0/12  -j RETURN
iptables -t nat -A XRAY -d 192.168.0.0/16 -j RETURN
iptables -t nat -A XRAY -d 224.0.0.0/4    -j RETURN
iptables -t nat -A XRAY -d 240.0.0.0/4    -j RETURN

# 2) 满足条件则重定向到 Xray redir 端口
iptables -t nat -A XRAY -p tcp -j REDIRECT --to-ports "$XRAY_PORT"

# 3) 本机发起：仅 ss 用户的 TCP 走 XRAY（其余用户不受影响）
iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner ss -j XRAY

# 4) 入站：仅匹配外部入口网卡 + 源端口为 49576 的 TCP 才走 XRAY
iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --sport "$IN_SPORT" -j XRAY