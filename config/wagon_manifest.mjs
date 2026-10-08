// Copyright (c) 2026, hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

import fs from "fs";
import path from "path";

// Reads the manifest the rake tasks in lib/tasks/assets.rake write for the
// active wagon composition, e.g. "css.json" or "js.json".
export function readWagonManifest(name) {
  const dir = process.env.WAGON_MANIFEST_DIR;
  if (!dir) {
    console.error(
      "WAGON_MANIFEST_DIR is not set. Run `bin/rails assets:build`, `assets:watch_js` or `assets:watch_css` instead of yarn directly."
    );
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(path.join(dir, name), "utf8"));
}
