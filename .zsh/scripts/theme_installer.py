"""Shared planning, integration and rollback for local native theme assets."""

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


@dataclass(frozen=True)
class Theme:
    name: str
    slug: str
    watch_wezterm: bool = False
    activation: str = ""


@dataclass
class Change:
    path: Path
    content: bytes
    mode: int | None = None


def theme_block(text, title, body, before=None, indent=""):
    """Replace one theme's block while preserving its active/inactive state."""
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
        "luzhu", "qingshan", "huangpao", "dracula", "catppuccin",
        "LuZhu", "QingShan", "HuangPao", "Dracula (Official)", "Catppuccin Mocha",
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


def integration_changes(root, theme, task_home):
    name, slug = theme.name, theme.slug
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
    contents["nvim"] = lua_selector(contents["nvim"], "colorscheme", slug, comma=True)
    plugin = f'  {{ dir = {json.dumps(str(root), ensure_ascii=False)}, name = "{name}.nvim", lazy = true }},'
    contents["nvim"] = managed_block(contents["nvim"], f"{name} plugin", plugin, after=r"^return \{\n", comment="--")
    contents["wezterm"] = lua_selector(contents["wezterm"], "config.color_scheme", name)
    if theme.watch_wezterm:
        contents["wezterm"] = managed_block(
            contents["wezterm"], f"{name} watch",
            f'wezterm.add_to_config_reload_watch_list(wezterm.home_dir .. "/.config/wezterm/colors/{name}.toml")',
            after=r"^local config[^\n]*\n", comment="--",
        )
    names = r"(?:LuZhu|QingShan|HuangPao|Catppuccin Mocha|Dracula)"
    contents["tmux"] = theme_block(
        contents["tmux"], f"{name} palette",
        (root / f"extras/tmux/{slug}.oh-my-tmux.conf").read_text(),
        before=rf"^# {names} palette \(",
    )
    colors = json.loads((root / "extras/palette.json").read_text())["colors"]
    popup = (
        f"set -g popup-style 'fg={colors['fg']},bg={colors['bg_float']}'\n"
        f"set -g popup-border-style 'fg={colors['border']},bg={colors['bg_float']}'"
    )
    contents["tmux"] = theme_block(contents["tmux"], name, popup, before=rf"^# {names} \(")
    contents["fzf"] = theme_block(contents["fzf"], name, (root / f"extras/fzf/{slug}.sh").read_text())
    contents["bat"] = theme_block(contents["bat"], name, f'--theme="{name}"')
    delta_section = re.search(r"^\[delta\]\n.*?(?=^\[|\Z)", contents["delta"], re.MULTILINE | re.DOTALL)
    if not delta_section:
        raise ValueError("Cannot find the existing [delta] section")
    delta_values = (root / f"extras/delta/{slug}.gitconfig").read_text().split("\n", 1)[1]
    delta_body = "\n".join(line.strip() for line in delta_values.splitlines())
    updated_delta = theme_block(delta_section.group(), name, delta_body, indent="    ")
    contents["delta"] = (
        contents["delta"][: delta_section.start()] + updated_delta + contents["delta"][delta_section.end() :]
    )
    return [Change(paths[key], value.encode()) for key, value in contents.items()]


def plan(root, theme, task_home, slides_dir, integrate=False):
    name, slug = theme.name, theme.slug
    destinations = {
        f"extras/wezterm/{name}.toml": f".config/wezterm/colors/{name}.toml",
        f"extras/tmux/{slug}.conf": f".config/tmux/themes/{slug}.conf",
        f"extras/tmux/{slug}.oh-my-tmux.conf": f".config/tmux/themes/{slug}.oh-my-tmux.conf",
        f"extras/fzf/{slug}.sh": f".config/fzf/themes/{slug}.sh",
        f"extras/bat/{name}.tmTheme": f".config/bat/themes/{name}.tmTheme",
        f"extras/delta/{slug}.gitconfig": f".config/delta/themes/{slug}.gitconfig",
        f"extras/alfred/{name} Dark Large.alfredappearance": f".config/alfred/themes/{name} Dark Large.alfredappearance",
        f"extras/alfred/{slug}.plist": f".config/alfred/themes/{slug}.plist",
    }
    changes = [Change(task_home / dest, (root / source).read_bytes()) for source, dest in destinations.items()]
    if integrate:
        # Preflight every transformation before any native files are installed.
        changes.extend(integration_changes(root, theme, task_home))
    if slides_dir.is_dir():
        changes.append(Change(slides_dir / f"{slug}_theme.json", (root / f"extras/slides/{slug}_theme.json").read_bytes()))
    return [
        change for change in changes
        if not change.path.exists()
        or change.path.read_bytes() != change.content
        or (change.mode is not None and stat.S_IMODE(change.path.stat().st_mode) != change.mode)
    ]


def atomic_write(path, content, mode):
    # Follow an existing symlink instead of replacing a user's dotfile link.
    target = path.resolve() if path.is_symlink() else path
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".theme-", dir=target.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            os.fchmod(stream.fileno(), mode)
            stream.write(content)
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def apply(changes, task_home, theme, writer=atomic_write):
    if not changes:
        return None
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    backups = task_home / f".config/{theme.slug}/backups" / stamp
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
            writer(change.path, change.content, change.mode if change.mode is not None else record["mode"])
            written.append(record)
    except Exception:
        for record in reversed(written):
            path = Path(record["path"])
            if record["backup"]:
                writer(path, Path(record["backup"]).read_bytes(), record["mode"])
            else:
                path.unlink(missing_ok=True)
        raise
    return backups


def main(theme, description):
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("source", type=Path, help=f"{theme.name}.nvim theme source directory")
    parser.add_argument("--home", type=Path, default=Path.home(), help="Target home directory")
    parser.add_argument("--slides-dir", type=Path, help="Existing slides-md-ppt directory")
    parser.add_argument("--integrate", action="store_true", help="Extend the existing local switch_all_theme configuration")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--no-cache", action="store_true", help="Skip bat cache build (e.g. for an isolated test directory)")
    args = parser.parse_args()
    root, task_home = args.source.expanduser().resolve(), args.home.expanduser().resolve()
    slides_dir = args.slides_dir.expanduser().resolve() if args.slides_dir else task_home / "github/slides-md-ppt"
    try:
        changes = plan(root, theme, task_home, slides_dir, args.integrate)
    except (ValueError, OSError) as error:
        raise SystemExit(str(error)) from error
    for change in changes:
        print(("Would write " if args.dry_run else "Install ") + str(change.path))
    if args.dry_run:
        return
    backups = apply(changes, task_home, theme)
    print("Backups: " + str(backups) if backups else f"{theme.name} files are already up to date.")
    if any(change.path.name == f"{theme.name}.tmTheme" for change in changes) and not args.no_cache:
        if task_home != Path.home().resolve():
            raise SystemExit("Assets installed; build bat cache in the target account (or use --no-cache).")
        if shutil.which("bat"):
            subprocess.run(["bat", "cache", "--build"], env={**os.environ, "BAT_CONFIG_PATH": os.devnull}, check=True)
    if args.integrate:
        print("Activate: switch_all_theme " + (theme.activation or theme.slug))
