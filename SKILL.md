---
name: arabic-rtl-fix
description: Fix reversed / left-to-right RTL text (Arabic, Hebrew, Persian, Urdu) in Electron desktop apps by injecting a dir="auto" bidi patch into the app's renderer. Use whenever the user complains that Arabic appears left-to-right, reversed, disconnected, or badly formatted in a desktop app (ZCode, Claude Code, Cursor, Slack, Discord, Notion, Obsidian, Postman, etc.), says something like العربي معكوس / مقلوب / من الشمال لليمين / مش مفهوم في التطبيق, asks to add RTL or bidi support to a desktop app, or asks to re-apply / roll back the Arabic patch after an app update. Covers Electron detection, fuse safety checks, patching, auto-swap watcher, rollback, and non-Electron alternatives.
---

# Arabic RTL Fix for Electron Apps

Electron apps render their UI with Chromium, which already *shapes* Arabic letters
correctly — the breakage is **direction**: pages default to LTR, so Arabic paragraphs
come out left-aligned with scrambled mixed Arabic/English lines. The fix is to make
text containers resolve their direction automatically (`dir="auto"`), exactly how
web apps like claude.ai do it. This skill injects a small, battle-tested snippet
into the app's renderer HTML.

**What this fixes:** chat messages, editors, previews, labels, input boxes — any
text in the Chromium DOM of the app.

**What this does NOT fix:** terminal panels built on xterm.js (a different, deeper
problem — see `references/alternatives.md`), and native (non-Electron) apps.

## Safety rules

1. **Never delete the original `app.asar`** — only rename it (`app.asar.pre-rtl-patch`). Rollback = rename back.
2. **Check Electron fuses first.** If `EnableEmbeddedAsarIntegrityValidation` or
   `OnlyLoadAppFromAsar` is Enabled, the app will refuse to run from a patched
   folder — stop and report to the user instead of breaking their app.
3. Keep every generated artifact in one patch folder (e.g. `~/<appname>-rtl-patch/`)
   so the user has one place for rollback/reapply.
4. Confirm free disk space ≥ 2× the size of `app.asar` before extracting.
5. Patching modifies a signed app. On macOS this invalidates the code signature —
   re-sign ad-hoc (see `references/troubleshooting.md`). On Windows this is a no-op.

## Procedure

### Step 1 — Confirm the app is Electron

Look for `<resources>/app.asar` next to the main executable:

| OS | Typical locations |
|---|---|
| Windows | `%LOCALAPPDATA%\Programs\<App>\resources\` |
| macOS | `/Applications/<App>.app/Contents/Resources/` |
| Linux | `/opt/<app>/resources/`, `/usr/lib/<app>/resources/`, `/usr/share/<app>/resources/` |

If there is no `app.asar` and no Electron binary nearby, the app is probably not
Electron → read `references/alternatives.md` and offer the user those routes instead.

### Step 2 — Check fuses (gate)

```bash
npx --yes @electron/fuses read --app "<path to the app executable>"
```

Proceed only if **both** are Disabled: `EnableEmbeddedAsarIntegrityValidation`,
`OnlyLoadAppFromAsar`. Otherwise stop and explain the risk to the user.

### Step 3 — Extract the app to a folder

Requires Node.js ≥ 16 (`node -v` to confirm; install it if missing and ask first).

```bash
cd "<resources dir>"
npx --yes @electron/asar extract app.asar app
```

Then merge native binaries that live outside the archive — without this the app
crashes on startup when it loads `.node` modules:

```bash
cp -r app.asar.unpacked/. app/        # skip silently if app.asar.unpacked doesn't exist
```

Verify: `app/package.json` exists and `app/out/` (or equivalent renderer dir) exists.

### Step 4 — Inject the patch

Use the bundled injector. It is idempotent (safe to re-run) and inserts the
snippet from `assets/rtl-snippet.html` before `</head>` (falls back to `</body>`):

```bash
node "<skill dir>/scripts/inject-rtl.mjs" <html file> [<html file> ...]
```

Which HTML files? Find the renderer entry points — typically everything with
`</head>` under the extracted app, excluding `node_modules`:

```bash
find app -name "*.html" -not -path "*/node_modules/*"
```

Patch the main `index.html` at minimum; extra panels are harmless to patch.

### Step 5 — Swap in the patched folder

Try renaming the archive:

```bash
mv app.asar app.asar.pre-rtl-patch
```

- **Rename succeeded** (app was closed): done — the app now loads `app/`.
- **"Device or resource busy" / Permission denied** (app is running — often the
  case when the user is talking to you *inside* the app): launch the bundled
  watcher, which swaps the file the moment the app fully quits:

  ```powershell
  powershell -NoProfile -Command "Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','<skill dir>/scripts/watch-swap.ps1','-ResourcesDir','<resources dir>','-ProcessName','<process name>'"
  ```

  Then tell the user: **quit the app completely** (tray icon → Quit, not just
  close the window), wait ~10 seconds, reopen. On macOS/Linux the plain `mv`
  usually works right away after the user quits.

### Step 6 — Generate per-app maintenance scripts

Create a patch folder (e.g. `~/<appname>-rtl-patch/`) containing small wrappers
with the concrete paths filled in, based on the bundled scripts:

- `rollback` — renames `app.asar.pre-rtl-patch` back and disables the patched folder
- `reapply` — re-runs extract + merge + inject + swap after an app **update**
  (updates restore a fresh `app.asar` and wipe the patched folder)

The simplest reapply wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill dir>/scripts/reapply.ps1" -ResourcesDir "<resources dir>"
```

### Step 7 — Verify and report

- Static check: each patched HTML contains the marker `RTL_PATCH_V1`
  (`grep "RTL_PATCH_V1" <html>`).
- Swap check: `<resources>/app.asar` gone, `app.asar.pre-rtl-patch` present,
  `app/` present.
- Ask the user to restart the app and read an Arabic paragraph. Success looks
  like: right-aligned, right-to-left, clean Arabic/English mixing.

Tell the user the two known caveats: (1) terminal panels inside the app are not
fixed by this patch, (2) the next app update removes the patch — re-run reapply.

## Re-apply after an update

Symptom: Arabic breaks again after the app updated (fresh `app.asar` is back).
With the app fully closed, run the reapply wrapper from Step 6. It extracts the
new asar, merges unpacked binaries, re-injects, and swaps — all idempotent.

## Rollback

With the app fully closed: rename `app.asar.pre-rtl-patch` → `app.asar` and
rename `app/` → `app.patched-unused` (kept so nothing is ever deleted without
the user's say-so). Bundled helper:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill dir>/scripts/rollback.ps1" -ResourcesDir "<resources dir>"
```

## When the app is not Electron, or the problem is a terminal

Read `references/alternatives.md` for the landscape: VS Code "RTL Terminal"
extension (xterm.js-based apps), bidi-capable terminals (Konsole, GNOME Terminal,
iTerm2 experimental, WezTerm experimental), and CLI wrappers (fribidi, dosu,
arabic-reshaper + python-bidi). Read `references/troubleshooting.md` when a step
fails (fuses enabled, locked files, macOS signature, app won't start).
