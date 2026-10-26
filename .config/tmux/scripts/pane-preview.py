#!/usr/bin/env python3
"""Preserve a tmux pane's ANSI colors while panning its preview by terminal cells."""

import argparse
import hashlib
import os
import re
import subprocess
import tempfile
import unicodedata
from contextlib import nullcontext
from pathlib import Path

CSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def cell_width(char):
    if unicodedata.combining(char) or unicodedata.category(char) in ("Mn", "Me", "Cf"):
        return 0
    return 2 if unicodedata.east_asian_width(char) in ("W", "F") else 1


def crop_ansi(line, offset, columns):
    """Replay SGR state across the cropped prefix; never slice an escape sequence."""
    result, position, index, visible_base = [], 0, 0, False
    while index < len(line):
        match = CSI.match(line, index)
        if match:
            if match.group().endswith("m"):
                result.append(match.group())
            index = match.end()
            continue
        char = line[index]
        index += 1
        width = cell_width(char)
        if width == 0:
            if visible_base:
                result.append(char)
            continue
        start, end = max(position, offset), min(position + width, offset + columns)
        visible_base = end - start == width
        if end > start:
            result.append(char if end - start == width else " " * (end - start))
        position += width
    # Include SGR changes beyond the right edge: the next source row may inherit
    # those colors. fzf carries ANSI state between preview lines, as tmux does.
    return "".join(result)


def number(path, default=0):
    try:
        return max(0, int(path.read_text()))
    except (FileNotFoundError, ValueError):
        return default


def write_number(path, value):
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(str(value))
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def preview(target, state_dir, move=None):
    state_dir.mkdir(parents=True, exist_ok=True)
    key = hashlib.sha256(target.encode()).hexdigest()[:20]
    offset_file, width_file, history_file, row_file, total_file = [
        state_dir / (key + suffix) for suffix in (".x", ".width", ".history", ".y", ".rows")
    ]
    columns = max(1, int(os.environ.get("FZF_PREVIEW_COLUMNS", "80")))
    height = max(1, int(os.environ.get("FZF_PREVIEW_LINES", "24")))
    offset = number(offset_file)
    if move:
        if move == "history":
            write_number(history_file, 1 - min(1, number(history_file)))
            write_number(row_file, 0)
            return
        if move in ("up", "down", "page-up", "page-down", "top", "bottom"):
            current, bottom = number(row_file), max(0, number(total_file) - height)
            delta = {"up": -1, "down": 1, "page-up": -height, "page-down": height, "top": -current, "bottom": bottom}[
                move
            ]
            write_number(row_file, max(0, min(current + delta, bottom)))
            return
        delta = {"left": -8, "right": 8, "reset": -offset}[move]
        write_number(offset_file, max(0, min(offset + delta, max(0, number(width_file, columns) - columns))))
        return
    pane = subprocess.run(
        ["tmux", "display-message", "-p", "-t", target, "#{pane_id}\t#{pane_width}"],
        capture_output=True,
        text=True,
        check=False,
    )
    parts = pane.stdout.strip().split("\t")
    if pane.returncode or len(parts) != 2 or not parts[1].isdigit():
        print("Window is no longer available")
        return
    pane_id, width = parts
    write_number(width_file, int(width))
    offset = min(number(offset_file), max(0, int(width) - columns))
    history = number(history_file) == 1
    command = ["tmux", "capture-pane", "-p", "-e", "-N", "-t", pane_id]
    if history:
        command.extend(["-S", "-2000"])
    capture = subprocess.run(command, capture_output=True, text=True, check=False)
    if capture.returncode:
        command.remove("-N")
        capture = subprocess.run(command, capture_output=True, text=True, check=False)
    if capture.returncode:
        print("Pane is no longer available")
        return
    lines = capture.stdout.splitlines()
    write_number(total_file, len(lines))
    row = min(number(row_file), max(0, len(lines) - height))
    # Preserve the SGR state inherited from rows above the viewport.
    prefix = "".join(crop_ansi(line, 0, 0) for line in lines[:row])
    resets = list(re.finditer(r"\x1b\[(?:0)?m", prefix))
    if resets:
        prefix = prefix[resets[-1].start() :]
    print(prefix, end="")
    for line in lines[row : row + height]:
        print(crop_ansi(line, offset, columns))
    print("\x1b[0m", end="")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target")
    parser.add_argument("state_dir", nargs="?", type=Path)
    parser.add_argument(
        "--move", choices=("left", "right", "reset", "history", "up", "down", "page-up", "page-down", "top", "bottom")
    )
    args = parser.parse_args()
    context = nullcontext(args.state_dir) if args.state_dir else tempfile.TemporaryDirectory(prefix="tmux-preview-")
    with context as state_dir:
        preview(args.target, Path(state_dir), args.move)


if __name__ == "__main__":
    main()
