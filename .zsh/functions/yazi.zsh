function y() {
	local tmp cwd
	tmp="$(mktemp /tmp/yazi-cwd.XXXXXX)"

	yazi "$@" --cwd-file="$tmp"

	cwd="$(cat -- "$tmp" 2>/dev/null || true)"

	if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd" || return
	fi
}
