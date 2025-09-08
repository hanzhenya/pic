#!/bin/zsh
# macOS Wi-Fi 网络切换脚本
# Author: YourName
# Version: 1.1
# Description:
#   通过一键选择切换 DHCP / 静态 IP 配置
#   仅支持 macOS (networksetup 工具)

set -e

# 确认运行环境
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ 本脚本仅支持 macOS"
    exit 1
fi

# 自动获取 Wi-Fi 服务名
WIFI_SERVICE=$(networksetup -listallnetworkservices | grep -v "*" | grep -i "wi[- ]fi")
if [ -z "$WIFI_SERVICE" ]; then
    echo "❌ 未找到 Wi-Fi 服务，请检查网络设置。"
    exit 1
fi

# 自动获取 Wi-Fi 接口名
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
if [ -z "$WIFI_DEVICE" ]; then
    echo "❌ 未找到 Wi-Fi 网卡，请检查网络设置。"
    exit 1
fi

# 定义网络配置（可扩展）
declare -A NET_IP NET_GW NET_DNS1 NET_DNS2
NET_IP[ROUTER253]="192.168.31.218"
NET_GW[ROUTER253]="192.168.31.253"
NET_DNS1[ROUTER253]="192.168.31.253"
NET_DNS2[ROUTER253]="223.5.5.5"

NET_IP[IPHONE_USB]="172.20.10.3"
NET_GW[IPHONE_USB]="172.20.10.2"
NET_DNS1[IPHONE_USB]="172.20.10.2"
NET_DNS2[IPHONE_USB]="223.5.5.5"

NET_IP[ROUTER251]="192.168.31.218"
NET_GW[ROUTER251]="192.168.31.251"
NET_DNS1[ROUTER251]="192.168.31.251"
NET_DNS2[ROUTER251]="223.5.5.5"

# 先重置为 DHCP
echo ">>> 重置为 DHCP ..."
sudo networksetup -setdhcp "$WIFI_SERVICE"
sudo networksetup -setdnsservers "$WIFI_SERVICE" Empty
sleep 2
CURRENT_IP=$(ipconfig getifaddr "$WIFI_DEVICE" || true)
echo "当前 DHCP IP: ${CURRENT_IP:-获取失败}"

# 菜单循环
while true; do
    echo
    echo "请选择网络模式："
    echo "0) DHCP 自动获取"
    echo "1) ROUTER253"
    echo "2) iPhone USB"
    echo "3) ROUTER251"
    echo "q) 退出"
    echo -n "输入选择: "
    read choice


    case "$choice" in
        0)
            echo ">>> 切换为 DHCP 模式..."
            sudo networksetup -setdhcp "$WIFI_SERVICE"
            sudo networksetup -setdnsservers "$WIFI_SERVICE" Empty
            ;;
        1) PROFILE="ROUTER253" ;;
        2) PROFILE="IPHONE_USB" ;;
        3) PROFILE="ROUTER251" ;;
        q|Q) echo "✅ 已退出"; exit 0 ;;
        *) echo "⚠️ 无效选择，请重试"; continue ;;
    esac

    # 应用静态配置
    if [ "$choice" != "0" ]; then
        echo ">>> 应用配置 [$PROFILE] ..."
        sudo networksetup -setmanual "$WIFI_SERVICE" \
            "${NET_IP[$PROFILE]}" 255.255.255.0 "${NET_GW[$PROFILE]}"
        sudo networksetup -setdnsservers "$WIFI_SERVICE" \
            "${NET_DNS1[$PROFILE]}" "${NET_DNS2[$PROFILE]}"
    fi

    echo ">>> 当前网络配置："
    networksetup -getinfo "$WIFI_SERVICE"
    echo "✅ 配置完成"
done
