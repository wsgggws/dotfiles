# 设置代理
proxy_enable() {
    if [[ $(uname -m) == "arm64" ]]; then
      export NO_PROXY=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*,172.17.*,172.18.*,172.19.*,172.20.*,172.21.*,172.22.*,172.23.*,172.24.*,172.25.*,172.26.*,172.27.*,172.28.*,172.29.*,172.30.*,172.31.*,*.local
      export HTTP_PROXY=http://127.0.0.1:7890 HTTPS_PROXY=http://127.0.0.1:7890 ALL_PROXY=http://127.0.0.1:7890
    else
      export NO_PROXY=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*,172.17.*,172.18.*,172.19.*,172.20.*,172.21.*,172.22.*,172.23.*,172.24.*,172.25.*,172.26.*,172.27.*,172.28.*,172.29.*,172.30.*,172.31.*,*.local
      export HTTP_PROXY=http://127.0.0.1:7897 HTTPS_PROXY=http://127.0.0.1:7897 ALL_PROXY=socks5://127.0.0.1:7897
    fi
}

# 取消代理
proxy_disable() {
    unset HTTPS_PROXY
    unset HTTP_PROXY
    unset ALL_PROXY
    unset NO_PROXY
    echo "Proxy disabled"
}

# 每次启动 Zsh 自动启用代理
proxy_enable
