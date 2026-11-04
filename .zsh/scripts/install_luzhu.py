#!/usr/bin/env python3
"""Install LuZhu assets, preserving selectors, backups and dotfile links."""

from pathlib import Path

import theme_installer as shared

ROOT = Path.home() / "github/LuZhu.nvim"
THEME = shared.Theme('LuZhu', 'luzhu', watch_wezterm=True, activation='')
Change = shared.Change
atomic_write = shared.atomic_write


def plan(task_home, slides_dir, integrate=False):
    return shared.plan(ROOT, THEME, task_home, slides_dir, integrate)


def apply(changes, task_home):
    return shared.apply(changes, task_home, THEME, writer=atomic_write)


def main():
    shared.main(THEME, __doc__)


if __name__ == "__main__":
    main()
