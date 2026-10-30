"""Distinct Alfred themes must retain separate registrations across switches."""

import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


@unittest.skipUnless(sys.platform == "darwin" and shutil.which("zsh"), "native macOS plist tools required")
class Coexistence(unittest.TestCase):
    def test_qingshan_and_luzhu_remain_registered_after_switching(self):
        with tempfile.TemporaryDirectory(prefix="alfred-coexist-") as directory:
            task = Path(directory)
            themes = task / "themes"
            themes.mkdir()
            for name in (
                "switch-theme.sh",
                "QingShan Dark Large.alfredappearance",
                "LuZhu Dark Large.alfredappearance",
                "qingshan.plist",
                "luzhu.plist",
            ):
                shutil.copyfile(ROOT / name, themes / name)
            profiles = {name: plistlib.loads((themes / f"{name}.plist").read_bytes()) for name in ("qingshan", "luzhu")}
            self.assertNotEqual(profiles["qingshan"]["lightthemeuid"], profiles["luzhu"]["lightthemeuid"])
            preferences = task / "Alfred.alfredpreferences"
            appearance = preferences / "preferences/local/test/appearance/prefs.plist"
            appearance.parent.mkdir(parents=True)
            appearance.write_bytes(plistlib.dumps({"unrelated": "preserved"}))
            binaries = task / "bin"
            binaries.mkdir()
            # Treat Alfred as closed; any native app call is a test failure.
            for name, body in {"pgrep": "exit 1", "osascript": "exit 99", "open": "exit 99"}.items():
                executable = binaries / name
                executable.write_text("#!/bin/sh\n" + body + "\n")
                executable.chmod(0o755)
            env = {
                **os.environ,
                "PATH": str(binaries) + os.pathsep + os.environ["PATH"],
                "ALFRED_PREFERENCES": str(preferences),
                "ALFRED_APPEARANCE_PREFS": str(appearance),
            }
            for name in ("qingshan", "luzhu", "qingshan"):
                result = subprocess.run(
                    ["zsh", str(themes / "switch-theme.sh"), name], env=env, capture_output=True, text=True, check=False
                )
                self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))
                current = plistlib.loads(appearance.read_bytes())
                self.assertEqual(current["lightthemeuid"], profiles[name]["lightthemeuid"])
                self.assertEqual(current["darkthemeuid"], profiles[name]["darkthemeuid"])
                self.assertEqual(current["unrelated"], "preserved")
            for name, display in (("qingshan", "QingShan Dark Large"), ("luzhu", "LuZhu Dark Large")):
                registered = preferences / "themes" / profiles[name]["lightthemeuid"] / "theme.json"
                self.assertEqual(json.loads(registered.read_text())["alfredtheme"]["name"], display)
                self.assertEqual(registered.read_bytes(), (themes / f"{display}.alfredappearance").read_bytes())
            before = appearance.read_bytes()
            shutil.copyfile(themes / "qingshan.plist", themes / "luzhu.plist")
            result = subprocess.run(
                ["zsh", str(themes / "switch-theme.sh"), "--check", "luzhu"],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, "")
            self.assertIn("distinct Alfred theme IDs", result.stderr)
            self.assertEqual(appearance.read_bytes(), before)
