# Non-Electron alternatives (RTL fixes landscape)

Use this reference when the target app is **not Electron**, when the broken area
is an **xterm.js terminal panel** (dir=auto cannot fix terminal cell grids), or
when the user asks for the general landscape of Arabic RTL support.

## Terminals with native bidi support

| Terminal | Platform | Status |
|---|---|---|
| Konsole (KDE) | Linux | Best-in-class, reference implementation |
| GNOME Terminal / VTE ≥ 3.34 | Linux | Working (some TUI regressions reported) |
| iTerm2 | macOS | Experimental: Settings → General → Experimental → "Enable support for right-to-left scripts" |
| WezTerm | All | Experimental bidi, must be enabled in config |
| mlterm | Linux | Long-standing bidi support |
| ❌ No support | — | Windows Terminal, Alacritty, foot, Ghostty, kitty, VS Code integrated terminal (xterm.js) |

## VS Code-family editors (VS Code, Cursor, Antigravity, Windsurf)

- **RTL Terminal** extension (`khalid-alzahrani.ar-terminal`, ~3.7K installs) —
  RTL-aware terminal with Arabic shaping + BiDi, works with AI CLI sessions
  (Claude Code etc.), `Ctrl+Shift+T`. Install: `code --install-extension khalid-alzahrani.ar-terminal`
- **Arabic Terminal (PowerShell)** (`IMuhammadAyman.vscode-arabic-terminal`) —
  Arabic-shaped PowerShell panel.
- Chat-panel direction fixes for AI assistants inside these editors:
  "Claude Code Arabic Fix" (ahmed-eragroup), "Claude Code RTL" (Sapphify),
  "Arabic RTL for Claude Code" (brahim-chai), "RTL Direction for Arabic Chat"
  (AbdallahElbatal, Antigravity).

## CLI-level workarounds (any terminal)

- Pipe through GNU FriBidi (recommended by kitty's docs): `your-command | fribidi`
- **dosu** (github.com/RustNegar/dosu) — Rust bidi terminal wrapper (Linux/macOS)
- Python output: `pip install arabic-reshaper python-bidi`, then
  `print(get_display(arabic_reshaper.reshape("نص عربي")))`
- **claude-arabic-terminal** (github.com/JamalMohafil/claude-arabic-terminal) —
  runs Claude Code inside a VS Code webview where Chromium does bidi (macOS/Windows)

## Key upstream issues to cite for the user

- xterm.js bidi: https://github.com/xtermjs/xterm.js/issues/701
- VS Code terminal RTL: https://github.com/microsoft/vscode/issues/28571
- Windows Terminal RTL: tracking issue on microsoft/terminal (open)
- kitty bidi: https://github.com/kovidgoyal/kitty/issues/2109
