deploy_k8s_web3() {
  local prev_dir=$(pwd)
  cd "$HOME/peak" || return
  python py/gitlab_publish_k8s.py web3_property web3-property-lb &&
  python py/gitlab_publish_k8s.py web3_property web3-property-celery &&
  python py/gitlab_publish_k8s.py web3_property web3-property &&
  python py/gitlab_publish_k8s.py web3_property web3-property-script
  cd "$prev_dir" || return
}

deploy_k8s_tg() {
  local prev_dir=$(pwd)
  cd "$HOME/peak" || return
  python py/gitlab_publish_k8s.py server_tg_lb server-tg-script &&
  python py/gitlab_publish_k8s.py server_tg_lb lb-tg-push &&
  python py/gitlab_publish_k8s.py server_tg_lb lb-tgpush-consumer
  cd "$prev_dir" || return
}

deploy_k8s_game() {
  local prev_dir=$(pwd)
  cd "$HOME/peak" || return
  python py/gitlab_publish_k8s.py bitslots_game lucky-bear-gray &&
  python py/gitlab_publish_k8s.py bitslots_game lucky-bear-prod &&
  python py/gitlab_publish_k8s.py bitslots_game lb-async-executor
  cd "$prev_dir" || return
}
