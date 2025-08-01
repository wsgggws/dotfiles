publish_web3() {
  local prev_dir=$(pwd)
  cd "$HOME/peak" || return
  python gitlab_publish_k8s.py web3_property web3-property-lb &&
  python gitlab_publish_k8s.py web3_property web3-property &&
  python gitlab_publish_k8s.py web3_property web3-property-script
  cd "$prev_dir" || return
}
