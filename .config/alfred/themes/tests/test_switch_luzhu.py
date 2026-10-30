"""Exercise the local Alfred switcher without touching running applications."""

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
class AlfredSwitcher(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="luzhu-alfred-tests-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.themes = self.root / "themes"
        self.themes.mkdir()
        self.script = self.themes / "switch-theme.sh"
        shutil.copyfile(ROOT / "switch-theme.sh", self.script)
        for name in ("LuZhu Dark Large.alfredappearance", "luzhu.plist"):
            shutil.copyfile(ROOT / name, self.themes / name)
        self.preferences = self.root / "Alfred.alfredpreferences"
        self.appearance = self.preferences / "preferences/local/test/appearance/prefs.plist"
        self.appearance.parent.mkdir(parents=True)
        profile = plistlib.loads((self.themes / "luzhu.plist").read_bytes())
        self.appearance.write_bytes(plistlib.dumps({**profile, "unrelated": "preserved"}))
        registered = self.preferences / "themes" / profile["lightthemeuid"] / "theme.json"
        registered.parent.mkdir(parents=True)
        shutil.copyfile(self.themes / "LuZhu Dark Large.alfredappearance", registered)
        binaries = self.root / "bin"
        binaries.mkdir()
        for name, content in {
            "pgrep": "#!/bin/sh\nexit 0\n",
            "osascript": '#!/bin/sh\nprintf "%s\\n" "$2" >> "$ALFRED_TEST_CALLS"\nprintf "native result\\n"\n',
        }.items():
            path = binaries / name
            path.write_text(content)
            path.chmod(0o755)
        self.calls = self.root / "calls"
        self.env = {
            **os.environ,
            "ALFRED_PREFERENCES": str(self.preferences),
            "ALFRED_APPEARANCE_PREFS": str(self.appearance),
            "ALFRED_TEST_CALLS": str(self.calls),
            "PATH": str(binaries) + os.pathsep + os.environ["PATH"],
        }

    def test_matching_disk_preferences_still_updates_running_application(self):
        result = subprocess.run(
            ["zsh", str(self.script), "luzhu"], env=self.env, capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")
        self.assertTrue(self.calls.exists(), "disk UIDs alone must not skip the live Alfred theme update")
        self.assertEqual(self.calls.read_text().splitlines(), ["LuZhu Dark Large"])
        self.assertEqual(plistlib.loads(self.appearance.read_bytes())["unrelated"], "preserved")

    def test_preflight_validates_files_without_updating_preferences_or_application(self):
        before = self.appearance.read_bytes()
        result = subprocess.run(
            ["zsh", str(self.script), "--check", "luzhu"],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.appearance.read_bytes(), before)
        self.assertFalse(self.calls.exists())
        (self.themes / "luzhu.plist").unlink()
        result = subprocess.run(
            ["zsh", str(self.script), "--check", "luzhu"],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertNotEqual(result.stderr, "")
        self.assertEqual(self.appearance.read_bytes(), before)
        self.assertFalse(self.calls.exists())

    def test_live_theme_failure_is_reported(self):
        (self.root / "bin/osascript").write_text("#!/bin/sh\nprintf 'native failure\\n' >&2\nexit 7\n")
        result = subprocess.run(
            ["zsh", str(self.script), "luzhu"], env=self.env, capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 7)
        self.assertEqual(result.stdout, "")
        self.assertIn("native failure", result.stderr)


if __name__ == "__main__":
    unittest.main()
