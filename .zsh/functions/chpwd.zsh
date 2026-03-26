function chpwd() {
    local env=""

    case "$PWD" in
        */web3_property|*/peak|*/platform)           env="web3_property" ;;
        */bitslots_game)                             env="bitslots_game" ;;
        */server_tg_lb)                              env="server_tg_lb" ;;
        */web3_user)                                 env="web3_user" ;;
        */server_lucky_admin)                        env="server_lucky_admin" ;;
        */lb_cs_gateway)                             env="lb_cs_gateway" ;;
        *) env="" ;;
    esac

    # 如果应激活的 env 为空 → deactivate
    if [[ -z "$env" ]]; then
        [[ -n "$CONDA_DEFAULT_ENV" ]] && conda deactivate
        return
    fi

    # 避免重复激活同一个 env
    if [[ "$CONDA_DEFAULT_ENV" != "$env" ]]; then
        conda activate "$env"
    fi
}
