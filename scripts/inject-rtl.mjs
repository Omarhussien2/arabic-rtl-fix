#!/usr/bin/env node
// RTL_PATCH_V1 injector — idempotently inserts assets/rtl-snippet.html
// before </head> (fallback </body>) of each given HTML file.
import { readFileSync, writeFileSync } from "node:fs";

const snippet = readFileSync(new URL("../assets/rtl-snippet.html", import.meta.url), "utf8");
const MARKER = "RTL_PATCH_V1";

let changed = 0;
for (const file of process.argv.slice(2)) {
  const html = readFileSync(file, "utf8");
  if (html.includes(MARKER)) {
    console.log(`SKIP (already patched): ${file}`);
    continue;
  }
  const headClose = html.search(/<\/head>/i);
  const bodyClose = html.search(/<\/body>/i);
  const at = headClose !== -1 ? headClose : bodyClose;
  if (at === -1) {
    console.log(`ERROR (no </head> or </body>): ${file}`);
    process.exitCode = 1;
    continue;
  }
  const patched = html.slice(0, at) + snippet + "\n    " + html.slice(at);
  writeFileSync(file, patched, "utf8");
  console.log(`PATCHED: ${file}`);
  changed++;
}
console.log(`done, ${changed} file(s) patched`);
