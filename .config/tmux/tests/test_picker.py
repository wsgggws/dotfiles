"""Exercise the real picker in an isolated tmux server, including keyboard input."""

import importlib.util
import os
import shlex
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


@unittest.skipUnless(all(shutil.which(tool) for tool in ("tmux", "fzf", "zsh")), "native tmux/fzf/zsh required")
class Picker(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="tmux-picker-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.socket = str(self.root / "tmux.sock")
        self.addCleanup(
            lambda: subprocess.run(["tmux", "-S", self.socket, "kill-server"], capture_output=True, check=False)
        )
        fixture = self.root / "fixture.py"
        fixture.write_text(
            "import time\n"
            "for row in range(100):\n"
            " print(f'HISTORY_{row:03d}', flush=True)\n"
            "print('\\x1b[2J\\x1b[H', end='', flush=True)\n"
            "for row in range(40):\n"
            " print(f'ROW_{row:02d} ' + '\\x1b[38;2;237;90;64mSOURCE_COLOR' + '\\x1b[0m' + '.'*120 + f'RIGHT_EDGE_{row:02d}', flush=True)\n"
            "time.sleep(60)\n"
        )
        self.tmux(
            "-f",
            "/dev/null",
            "new-session",
            "-d",
            "-s",
            "fixture",
            "-n",
            "source",
            "-x",
            "180",
            "-y",
            "45",
            f"python3 {shlex.quote(str(fixture))}",
        )
        self.wait_screen("fixture:0.0", "ROW_39")
        self.env = {**os.environ, "TMUX": self.socket + ",1,0"}
        self.state = self.root / "state"
        self.state.mkdir()

    def tmux(self, *args):
        return subprocess.check_output(["tmux", "-S", self.socket, *args], text=True)

    def wait_screen(self, target, marker, present=True):
        screen = ""
        for _ in range(60):
            screen = self.tmux("capture-pane", "-p", "-t", target)
            if (marker in screen) == present:
                return screen
            time.sleep(0.05)
        self.fail(f"expected {marker!r} present={present} in native picker: {screen[:1200]!r}")

    def test_preview_preserves_source_colors(self):
        output = subprocess.check_output(
            ["zsh", str(ROOT / "scripts/pane-preview.zsh"), "fixture:0.0", str(self.state)],
            env={**self.env, "FZF_PREVIEW_COLUMNS": "90", "FZF_PREVIEW_LINES": "24"},
            text=True,
        )
        self.assertIn("\x1b[38;2;237;90;64m", output)
        self.assertTrue(output.startswith("ROW_00 "), "preview starts directly with pane content")
        self.assertEqual(output.count("\n"), 24, "all preview rows are available for content")
        self.assertNotIn("SCREEN", output)
        self.assertNotIn(" · rows ", output)
        self.assertNotIn(" · cols ", output)

    def test_real_picker_scrolls_in_both_axes(self):
        task_home = self.root / "home"
        theme = task_home / ".config/fzf/theme.sh"
        theme.parent.mkdir(parents=True)
        theme.write_text(
            "FZF_THEME_NAME='Fixture'\n"
            "FZF_THEME_COLOR='fg:#cccccc,bg:#222222,preview-fg:#cccccc,preview-bg:#111111'\n"
            "FZF_THEME_PREVIEW_CMD='cat --'\n"
        )
        # The agent's command runner sets NO_COLOR; the user's terminal does not.
        command = f"env -u NO_COLOR COLORTERM=truecolor ALLTHEME_HOME={shlex.quote(str(task_home))} zsh {shlex.quote(str(ROOT / 'scripts/window-picker.zsh'))}"
        self.tmux("new-window", "-d", "-t", "fixture:1", "-n", "picker", command)
        self.tmux("set-window-option", "-t", "fixture:1", "window-size", "manual")
        self.tmux("resize-window", "-t", "fixture:1", "-x", "140", "-y", "25")
        self.tmux("send-keys", "-t", "fixture:1.0", "fixture:source")
        initial = self.wait_screen("fixture:1.0", "ROW_00")
        self.assertNotIn("RIGHT_EDGE", initial)
        self.assertNotIn("SCREEN", initial)
        ansi = self.tmux("capture-pane", "-p", "-e", "-t", "fixture:1.0")
        self.assertIn("38;2;237;90;64", ansi, "fzf must render the source pane's syntax colors")
        for _ in range(8):
            self.tmux("send-keys", "-t", "fixture:1.0", "S-Right")
        self.wait_screen("fixture:1.0", "RIGHT_EDGE")
        self.tmux("send-keys", "-t", "fixture:1.0", "NPage")
        self.wait_screen("fixture:1.0", "RIGHT_EDGE_39")
        for _ in range(8):
            self.tmux("send-keys", "-t", "fixture:1.0", "S-Left")
        self.wait_screen("fixture:1.0", "ROW_39")
        self.tmux("send-keys", "-t", "fixture:1.0", "PPage")
        restored = self.wait_screen("fixture:1.0", "ROW_00")
        self.assertNotIn("RIGHT_EDGE", restored)
        self.tmux("send-keys", "-t", "fixture:1.0", "M-b")
        self.wait_screen("fixture:1.0", "HISTORY_000")
        self.tmux("send-keys", "-t", "fixture:1.0", "M-b")
        self.wait_screen("fixture:1.0", "ROW_00")
        # SGR mouse wheel events inside the right-hand preview, then back up.
        self.tmux("send-keys", "-t", "fixture:1.0", "-l", "\x1b[<65;100;5M")
        scrolled = self.wait_screen("fixture:1.0", "ROW_00", present=False)
        self.assertIn("ROW_01", scrolled)
        self.tmux("send-keys", "-t", "fixture:1.0", "-l", "\x1b[<64;100;5M")
        self.wait_screen("fixture:1.0", "ROW_00")
        self.tmux("send-keys", "-t", "fixture:1.0", "Escape")


class AnsiCrop(unittest.TestCase):
    def setUp(self):
        spec = importlib.util.spec_from_file_location("pane_preview", ROOT / "scripts/pane-preview.py")
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def test_cjk_and_combining_marks_are_cropped_by_display_cells(self):
        self.assertEqual(self.module.crop_ansi("青山e\u0301abc", 1, 3), " 山")
        self.assertEqual(self.module.crop_ansi("青山e\u0301abc", 4, 2), "e\u0301a")

    def test_crop_preserves_styles_and_end_of_line_state(self):
        output = self.module.crop_ansi("\x1b[31mLEFT\x1b[32mRIGHT\x1b[34m", 4, 5)
        self.assertEqual(output, "\x1b[31m\x1b[32mRIGHT\x1b[34m")
