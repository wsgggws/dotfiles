function chpwd() {
    case "$PWD" in
        */api.rss.navydev.top)
            conda activate NS11
            ;;
        */ReadLecture-web-server)
            conda activate RL
            ;;
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
        */AI-Video-Transcriber)
            conda activate Transcriber
            ;;
        *)
          # 确保彻底退出所有 conda env
          while [[ "$CONDA_DEFAULT_ENV" != "" ]]; do
            conda deactivate
          done
          ;;
    esac
}
