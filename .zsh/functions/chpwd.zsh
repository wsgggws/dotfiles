function chpwd() {
    case "$PWD" in
        */api.rss.navydev.top)
            conda activate NS11
            ;;
        */ReadLecture-web-server)
            conda activate RL
            ;;
        */web3_property)
            conda activate PEAK
            ;;
        */peak)
            conda activate PEAK
            ;;
        */bitslots_game)
            conda activate GAME39
            ;;
        */server_tg_lb)
            conda activate SERVER39
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
            conda deactivate && conda deactivate
            ;;
    esac
}
