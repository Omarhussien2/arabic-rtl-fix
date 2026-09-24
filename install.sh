#!/usr/bin/env bash
# arabic-rtl-fix installer (macOS / Linux)
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest_root="$HOME/.agents/skills"
dest="$dest_root/arabic-rtl-fix"

mkdir -p "$dest_root"
rm -rf "$dest"
cp -r "$src" "$dest"
echo "Installed: $dest"
echo 'Restart your AI agent (ZCode / Claude Code / Cursor) and say:'
echo '  "العربي معكوس في تطبيق X، صلّحه"'
