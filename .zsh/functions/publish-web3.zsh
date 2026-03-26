publish_web3() {
  local prev_dir=$(pwd)
  cd "$HOME/peak" || return
  python py/gitlab_publish_k8s.py web3_property web3-property-lb &&
  python py/gitlab_publish_k8s.py web3_property web3-property-celery &&
  python py/gitlab_publish_k8s.py web3_property web3-property &&
  python py/gitlab_publish_k8s.py web3_property web3-property-script
  cd "$prev_dir" || return
}
