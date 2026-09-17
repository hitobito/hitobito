// Copyright (c) 2026, hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// Compiles every SCSS entrypoint - the core's, plus the ones the active wagons
// bring along (tmp/wagon_css_manifest.json, written by
// `rake assets:wagon_css_manifest`) - with dart-sass.

import { spawn } from "child_process";
import { globSync } from "glob";
import fs from "fs";
import path from "path";

const WAGON_MANIFEST_PATH = "tmp/wagon_css_manifest.json";
const CORE_STYLESHEETS = "app/assets/stylesheets";
const ENTRYPOINT_DIR = "entrypoints";

const { buildDir, wagonStylesheetPaths } = JSON.parse(fs.readFileSync(WAGON_MANIFEST_PATH, "utf8"));

// Output goes to a subdirectory per instance, i.e. per wagon composition (see
// config/initializers/assets.rb), so switching wagons, or running specs from a
// wagon's own directory, doesn't clobber a valid build.
const OUTPUT_DIR = path.join("app/assets/builds", buildDir);
fs.mkdirSync(OUTPUT_DIR, { recursive: true });

// Entrypoints live in their own directory, and deliberately not next to the
// partials: sass resolves an @import relative to the importing file before it
// consults any load path, so an entrypoint sitting beside the core's hitobito/
// would always find the core's customizable partials and never a wagon's.
const entries = [CORE_STYLESHEETS, ...wagonStylesheetPaths].flatMap((root) =>
  globSync(`${root}/${ENTRYPOINT_DIR}/*.scss`).filter((file) => !path.basename(file).startsWith("_"))
);

if (entries.length === 0) {
  console.error(`No .scss entrypoints found in ${CORE_STYLESHEETS}/${ENTRYPOINT_DIR}`);
  process.exit(1);
}

const args = [
  ...entries.map((entry) => `${entry}:${path.join(OUTPUT_DIR, `${path.basename(entry, ".scss")}.css`)}`),
  // The wagons come first, so that a wagon's hitobito/customizable/_variables.scss
  // (and _fonts/_wagon) shadows the core's - this is what makes those files
  // customizable. It also means a wagon could shadow any other core partial by
  // reproducing its path, which no wagon currently does.
  ...wagonStylesheetPaths.map((wagonPath) => `--load-path=${wagonPath}`),
  `--load-path=${CORE_STYLESHEETS}`,
  "--load-path=node_modules",
  // For "app/components/steps_component".
  "--load-path=.",
  "--no-source-map",
  ...(process.env.NODE_ENV === "production" ? ["--style=compressed"] : []),
  ...process.argv.slice(2), // e.g. --watch, forwarded from `yarn build:css --watch`
];

const sass = spawn("npx", ["sass", ...args], { stdio: "inherit" });
sass.on("exit", (code) => process.exit(code ?? 1));
