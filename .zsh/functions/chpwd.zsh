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
        *)
            conda deactivate && conda deactivate
            ;;
    esac
}
