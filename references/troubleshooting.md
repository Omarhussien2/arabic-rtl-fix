# Troubleshooting

## Fuses gate failed (integrity enabled / OnlyLoadAppFromAsar)

The app validates its archive or refuses folder mode. **Do not patch.** Explain to
the user that this app protects its code and the dir=auto injection cannot be
applied safely; offer the alternatives reference instead.

## `mv app.asar …` fails: "Device or resource busy" / "Permission denied"

The app is running and holds the file (typical when the user is chatting with you
inside the very app being patched). Use the watcher (`scripts/watch-swap.ps1`)
and have the user fully quit (tray → Quit) and reopen. If it still fails after a
full quit, check for background/helper processes of the same app in Task Manager.

## App won't start after the swap

1. Roll back immediately (rename `app.asar.pre-rtl-patch` → `app.asar`,
   move `app/` aside).
2. Most common cause: native modules not merged — re-run
   `cp -r app.asar.unpacked/. app/` and confirm `.node`/`.dll` files exist under
   `app/node_modules/`.
3. Second cause: `package.json` "main" entry not present in the extracted folder
   (partial extraction, disk full) — re-extract with enough free space.

## Windows: extraction ran but app folder is huge/slow

Antivirus may scan thousands of extracted files. Wait it out; exclude the app
folder from real-time scanning if the user wants faster loads.

## macOS specifics

- Paths: `/Applications/<App>.app/Contents/Resources/`
- Modifying files inside `.app` **invalidates the code signature**. Gatekeeper
  usually allows already-approved apps, but some apps enforce their own signature
  checks. Fix by ad-hoc re-signing:
  ```bash
  codesign --force --deep --sign - "/Applications/<App>.app"
  ```
- If the app is protected by SIP-protected locations or the user lacks write
  access, they may need to copy the app to ~/Applications first.

## Linux specifics

- System locations (`/opt`, `/usr`) need sudo — prefer patching only with the
  user's explicit consent, and note that package updates overwrite the patch.
- Some distros ship Electron apps with system Electron; resources may live under
  `/usr/share/<app>` without an `app.asar` (unpacked by the packager) — in that
  case inject directly into the on-disk HTML files, no extraction needed.

## Patch worked, then disappeared

The app auto-updated (electron-updater): fresh `app.asar` restored, patched
folder wiped. That is expected — run the reapply script (see SKILL.md Step 6).
Suggest the user pause auto-updates if this annoys them.

## Arabic still LTR in one specific panel

Likely an xterm.js terminal panel or a canvas/WebGL-rendered surface — the DOM
patch cannot reach it. Confirm with the user which panel, then point to
`references/alternatives.md`.
