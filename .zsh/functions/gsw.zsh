# gsw: git switch 增强版。
# 好处：不依赖 post-checkout hook，避免被项目里的 .husky/core.hooksPath 覆盖。
# 行为：切换成功后，如果当前分支是 master/main，则自动 pull --rebase。
# 补全：支持本地分支、origin 分支，以及 "-" 切回上一个分支。
unalias gsw 2>/dev/null

gsw() {
  git switch "$@" || return

  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return

  if [[ "$branch" == "master" || "$branch" == "main" ]]; then
    echo "Switched to $branch, pulling latest..."
    git pull origin "$branch" --rebase
  fi
}

if (( $+functions[compdef] )); then
  # 自定义轻量补全；不用 _git 的 git-switch 补全，避免部分环境下解析报错。
  _gsw() {
    local -a branches
    branches=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null | sed 's#^origin/##' | sort -u)}")
    branches=("-" "${branches[@]}")
    _describe -t branches 'branch' branches
  }

  compdef _gsw gsw
fi
