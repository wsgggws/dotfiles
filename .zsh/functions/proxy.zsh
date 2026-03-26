# 设置代理
proxy_enable() {
    if [[ $(uname -m) == "arm64" ]]; then
      export all_proxy=http://127.0.0.1:7890
    else
      export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897
    fi
}

# 取消代理
proxy_disable() {
    unset https_proxy
    unset http_proxy
    unset all_proxy
    echo "Proxy disabled"
}

# 每次启动 Zsh 自动启用代理
proxy_enable
