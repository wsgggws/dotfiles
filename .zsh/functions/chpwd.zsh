function chpwd() {
    case "$PWD" in
        */web3_property|*/peak)
            conda activate web3_property
            ;;
        */bitslots_game)
            conda activate bitslots_game
            ;;
        */server_tg_lb)
            conda activate server_tg_lb
            ;;
        */web3_user)
            conda activate web3_user
            ;;
        */server_lucky_admin)
            conda activate server_lucky_admin
            ;;
        *)
          # 确保彻底退出所有 conda env
          while [[ "$CONDA_DEFAULT_ENV" != "" ]]; do
            conda deactivate
          done
          ;;
    esac
}
