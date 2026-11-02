#!/usr/bin/env python3
"""Install LuZhu assets into this account, optionally updating its selectors.

This local helper requires an explicit theme source directory. It backs up
planned writes and preserves dotfile links. It does not install shell functions,
Alfred automation, or the tmux picker; those are maintained in their own config
directories.
"""

import argparse
import json
import os
import re
import shutil
import stat
import subprocess
import tempfile
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path.home() / "github/LuZhu.nvim"


@dataclass
class Change:
    path: Path
    content: bytes
    mode: int | None = None


def theme_block(text, title, body, before=None, indent=""):
    """Update only LuZhu's block, preserving its active/inactive state."""
    pattern = re.compile(
        rf"^{re.escape(indent)}# {re.escape(title)} \((active|inactive)\)\n(?:[^\n]+\n)*\n?",
        re.MULTILINE,
    )
    matches = list(pattern.finditer(text))
    if len(matches) > 1:
        raise ValueError(f"Duplicate {title} blocks")
    state = matches[0].group(1) if matches else "inactive"
    prefix = "" if state == "active" else "# "
    block = indent + f"# {title} ({state})\n"
    block += "".join(indent + prefix + line + "\n" for line in body.strip().splitlines()) + "\n"
    if matches:
        match = matches[0]
        return text[: match.start()] + block + text[match.end() :]
    if before:
        anchor = re.search(before, text, re.MULTILINE)
        if not anchor:
            raise ValueError(f"Cannot locate insertion point for {title}")
        return text[: anchor.start()] + block + text[anchor.start() :]
    return text.rstrip() + "\n\n" + block


def lua_selector(text, setting, value, comma=False):
    if re.search(rf'^[ \t]*(?:-- )?{re.escape(setting)} = "{re.escape(value)}"', text, re.MULTILINE):
        return text
    pattern = re.compile(rf'^([ \t]*){re.escape(setting)} = "([^"]+)"[^\n]*$', re.MULTILINE)
    matches = list(pattern.finditer(text))
    if len(matches) != 1 or matches[0].group(2) not in {
        "qingshan",
        "QingShan",
        "huangpao",
        "dracula",
        "catppuccin",
        "HuangPao",
        "Dracula (Official)",
        "Catppuccin Mocha",
    }:
        raise ValueError(f"Expected one recognized active Lua selector: {setting}")
    match = matches[0]
    addition = f'\n{match.group(1)}-- {setting} = "{value}"' + ("," if comma else "")
    return text[: match.end()] + addition + text[match.end() :]


def managed_block(text, label, payload, after=None, comment="#"):
    begin, end = f"{comment} BEGIN {label}", f"{comment} END {label}"
    block = begin + "\n" + payload.rstrip() + "\n" + end + "\n"
    pattern = re.compile(rf"^[ \t]*{re.escape(begin)}\n.*?^[ \t]*{re.escape(end)}\n?", re.MULTILINE | re.DOTALL)
    if pattern.search(text):
        return pattern.sub(lambda _: block, text)
    if after:
        match = re.search(after, text, re.MULTILINE)
        if not match:
            raise ValueError(f"Cannot locate insertion point for {label}")
        return text[: match.end()] + block + text[match.end() :]
    return text.rstrip() + "\n\n" + block


def integration_changes(task_home):
    paths = {
        "nvim": task_home / ".config/nvim/lua/plugins/colorschema.lua",
        "wezterm": task_home / ".wezterm.lua",
        "tmux": task_home / ".tmux.conf.local",
        "fzf": task_home / ".config/fzf/theme.sh",
        "bat": task_home / ".config/bat/config",
        "delta": task_home / ".gitconfig",
    }
    missing = [str(path) for path in paths.values() if not path.is_file()]
    if missing:
        raise ValueError("--integrate requires the existing switch_all_theme layout:\n" + "\n".join(missing))
    contents = {key: path.read_text() for key, path in paths.items()}
    contents["nvim"] = lua_selector(contents["nvim"], "colorscheme", "luzhu", comma=True)
    plugin = f'  {{ dir = {json.dumps(str(ROOT), ensure_ascii=False)}, name = "LuZhu.nvim", lazy = true }},'
    contents["nvim"] = managed_block(contents["nvim"], "LuZhu plugin", plugin, after=r"^return \{\n", comment="--")
    contents["wezterm"] = lua_selector(contents["wezterm"], "config.color_scheme", "LuZhu")
    contents["wezterm"] = managed_block(
        contents["wezterm"],
        "LuZhu watch",
        'wezterm.add_to_config_reload_watch_list(wezterm.home_dir .. "/.config/wezterm/colors/LuZhu.toml")',
        after=r"^local config[^\n]*\n",
        comment="--",
    )
    contents["tmux"] = theme_block(
        contents["tmux"],
        "LuZhu palette",
        (ROOT / "extras/tmux/luzhu.oh-my-tmux.conf").read_text(),
        before=r"^# (?:QingShan|HuangPao|Catppuccin Mocha|Dracula) palette \(",
    )
    p = json.loads((ROOT / "extras/palette.json").read_text())["colors"]
    popup = f"set -g popup-style 'fg={p['fg']},bg={p['bg_float']}'\nset -g popup-border-style 'fg={p['border']},bg={p['bg_float']}'"
    contents["tmux"] = theme_block(
        contents["tmux"],
        "LuZhu",
        popup,
        before=r"^# (?:QingShan|HuangPao|Catppuccin Mocha|Dracula) \(",
    )
    contents["fzf"] = theme_block(contents["fzf"], "LuZhu", (ROOT / "extras/fzf/luzhu.sh").read_text())
    contents["bat"] = theme_block(contents["bat"], "LuZhu", '--theme="LuZhu"')
    delta_section = re.search(r"^\[delta\]\n.*?(?=^\[|\Z)", contents["delta"], re.MULTILINE | re.DOTALL)
    if not delta_section:
        raise ValueError("Cannot find the existing [delta] section")
    delta_values = (ROOT / "extras/delta/luzhu.gitconfig").read_text().split("\n", 1)[1]
    delta_body = "\n".join(line.strip() for line in delta_values.splitlines())
    updated_delta = theme_block(delta_section.group(), "LuZhu", delta_body, indent="    ")
    contents["delta"] = (
        contents["delta"][: delta_section.start()] + updated_delta + contents["delta"][delta_section.end() :]
    )
    return [Change(paths[key], value.encode()) for key, value in contents.items()]


def plan(task_home, slides_dir, integrate=False):
    destinations = {
        "extras/wezterm/LuZhu.toml": ".config/wezterm/colors/LuZhu.toml",
        "extras/tmux/luzhu.conf": ".config/tmux/themes/luzhu.conf",
        "extras/tmux/luzhu.oh-my-tmux.conf": ".config/tmux/themes/luzhu.oh-my-tmux.conf",
        "extras/fzf/luzhu.sh": ".config/fzf/themes/luzhu.sh",
        "extras/bat/LuZhu.tmTheme": ".config/bat/themes/LuZhu.tmTheme",
        "extras/delta/luzhu.gitconfig": ".config/delta/themes/luzhu.gitconfig",
        "extras/alfred/LuZhu Dark Large.alfredappearance": ".config/alfred/themes/LuZhu Dark Large.alfredappearance",
        "extras/alfred/luzhu.plist": ".config/alfred/themes/luzhu.plist",
    }
    changes = [Change(task_home / dest, (ROOT / source).read_bytes()) for source, dest in destinations.items()]
    if integrate:
        # Preflight every transformation before any native files are installed.
        changes.extend(integration_changes(task_home))
    if slides_dir.is_dir():
        changes.append(Change(slides_dir / "luzhu_theme.json", (ROOT / "extras/slides/luzhu_theme.json").read_bytes()))
    return [
        change
        for change in changes
        if not change.path.exists()
        or change.path.read_bytes() != change.content
        or (change.mode is not None and stat.S_IMODE(change.path.stat().st_mode) != change.mode)
    ]


def atomic_write(path, content, mode):
    # Follow an existing symlink instead of replacing a user's dotfile link.
    target = path.resolve() if path.is_symlink() else path
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".luzhu-", dir=target.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            os.fchmod(stream.fileno(), mode)
            stream.write(content)
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def apply(changes, task_home):
    if not changes:
        return None
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    backups = task_home / ".config/luzhu/backups" / stamp
    backups.mkdir(parents=True, mode=0o700)
    records = []
    for index, change in enumerate(changes):
        exists = change.path.exists()
        mode = stat.S_IMODE(change.path.stat().st_mode) if exists else 0o644
        backup = backups / f"{index:02d}-{change.path.name}" if exists else None
        if backup:
            shutil.copy2(change.path, backup)
        records.append({"path": str(change.path), "backup": str(backup) if backup else None, "mode": mode})
    (backups / "manifest.json").write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n")
    written = []
    try:
        for change, record in zip(changes, records):
            atomic_write(change.path, change.content, change.mode if change.mode is not None else record["mode"])
            written.append(record)
    except Exception:
        for record in reversed(written):
            path = Path(record["path"])
            if record["backup"]:
                atomic_write(path, Path(record["backup"]).read_bytes(), record["mode"])
            else:
                path.unlink(missing_ok=True)
        raise
    return backups


def main():
    global ROOT
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="LuZhu.nvim theme source directory")
    parser.add_argument("--home", type=Path, default=Path.home(), help="Target home directory")
    parser.add_argument("--slides-dir", type=Path, help="Existing slides-md-ppt directory")
    parser.add_argument(
        "--integrate", action="store_true", help="Extend the existing local switch_all_theme configuration"
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--no-cache", action="store_true", help="Skip bat cache build (e.g. for an isolated test directory)"
    )
    args = parser.parse_args()
    ROOT = args.source.expanduser().resolve()
    task_home = args.home.expanduser().resolve()
    slides_dir = args.slides_dir.expanduser().resolve() if args.slides_dir else task_home / "github/slides-md-ppt"
    try:
        changes = plan(task_home, slides_dir, args.integrate)
    except (ValueError, OSError) as error:
        raise SystemExit(str(error)) from error
    for change in changes:
        print(("Would write " if args.dry_run else "Install ") + str(change.path))
    if args.dry_run:
        return
    backups = apply(changes, task_home)
    if backups:
        print("Backups: " + str(backups))
    else:
        print("LuZhu files are already up to date.")
    theme_changed = any(change.path.name == "LuZhu.tmTheme" for change in changes)
    if theme_changed and not args.no_cache:
        if task_home != Path.home().resolve():
            raise SystemExit("Assets installed; build bat cache in the target account (or use --no-cache).")
        if shutil.which("bat"):
            env = {**os.environ, "BAT_CONFIG_PATH": os.devnull}
            subprocess.run(["bat", "cache", "--build"], env=env, check=True)
    if args.integrate:
        print("Activate: switch_all_theme luzhu")


if __name__ == "__main__":
    main()
