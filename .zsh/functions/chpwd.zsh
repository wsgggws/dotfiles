function chpwd() {
    case "$PWD" in
        */news-summary)
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
        *)
            conda deactivate && conda deactivate
            ;;
    esac
}
