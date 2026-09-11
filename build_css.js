// Copyright (c) 2026, hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// Compiles every entry rendered by `rake assets:render_scss_entries`
// (core's application/oauth/print + wagon-owned packs, e.g.
// hitobito_sac_cas's agenda.scss) via dart-sass. `--load-path=.` lets
// entries `@import` core files by a plain `app/javascript/...` path.

const { execFileSync, spawn } = require("child_process");
const { sync: globSync } = require("glob");
const fs = require("fs");
const path = require("path");

const WAGON_LOAD_PATHS_PATH = "tmp/wagon_scss_load_paths.json";
const watch = process.argv.includes("--watch");

// `rake assets:render_scss_entries assets:wagon_scss_load_paths` (which pulls
// in the *active* wagon's _variables.scss/_fonts.scss/_wagon.scss via
// WebpackHelper, and lists each active wagon's root directory) is wired as a
// prerequisite of the Rake task `css:build`, but this script also runs
// directly via `yarn build:css` (e.g. the Procfile's `css` process in
// normal dev mode) - a plain `yarn`/`node` invocation never goes through
// Rake at all, so those steps need to run here too, or switching WAGONS
// would silently keep serving whichever wagon was last rendered.
execFileSync("bundle", ["exec", "rake", "assets:render_scss_entries", "assets:wagon_scss_load_paths"], { stdio: "inherit" });

const { signature, wagonRoots } = JSON.parse(fs.readFileSync(WAGON_LOAD_PATHS_PATH, "utf8"));

// Output (and the rendered SCSS) is split into a subdirectory per "wagon
// signature" (see config/initializers/assets.rb) so switching wagons, or
// running specs from a wagon's own directory, doesn't clobber a valid build.
const GENERATED_SCSS_DIR = path.join("app/assets/stylesheets_generated", signature);
const OUTPUT_DIR = path.join("app/assets/builds", signature);
fs.mkdirSync(OUTPUT_DIR, { recursive: true });

const entries = globSync(`${GENERATED_SCSS_DIR}/*.scss`);

if (entries.length === 0) {
  console.error(`No .scss entries found in ${GENERATED_SCSS_DIR} - did "rake assets:render_scss_entries" run?`);
  process.exit(1);
}

const outputs = entries.map((entry) => path.join(OUTPUT_DIR, `${path.basename(entry, ".scss")}.css`));

// Prune stale CSS from a previous build under this signature - only
// touches *.css, so this can't clobber the JS build's own outputs.
const outputBasenames = new Set(outputs.map((o) => path.basename(o)));
for (const existing of globSync(`${OUTPUT_DIR}/*.css`)) {
  if (!outputBasenames.has(path.basename(existing))) fs.unlinkSync(existing);
}

const args = [
  ...entries.map((entry, i) => `${entry}:${outputs[i]}`),
  "--load-path=node_modules",
  "--load-path=.",
  // For dart-sass's own --watch to monitor these too - the @imports
  // themselves are absolute paths and already resolve fine without this.
  ...wagonRoots.map((wagonRoot) => `--load-path=${wagonRoot}`),
  "--no-source-map",
  "--style=compressed",
  ...process.argv.slice(2), // e.g. --watch, forwarded from `yarn build:css --watch`
];

// FontAwesome's own CSS hardcodes `url(../webfonts/...)` (correct within
// its npm package layout, wrong here since compiled CSS lives at the
// build dir's root) - rewrite to a bare filename, matching the flat path
// registered in config/initializers/assets.rb.
function fixFontAwesomeUrls() {
  for (const output of outputs) {
    if (!fs.existsSync(output)) continue;
    const content = fs.readFileSync(output, "utf8");
    const fixed = content.replace(/url\((['"]?)\.\.\/webfonts\//g, "url($1");
    if (fixed !== content) fs.writeFileSync(output, fixed);
  }
}

const sass = spawn("npx", ["sass", ...args], { stdio: watch ? ["inherit", "pipe", "inherit"] : "inherit" });

if (watch) {
  // --watch's `sass` process never exits, so the fix-up must run after
  // *every* recompile - triggered by watching stdout for "Compiled ",
  // dart-sass's only signal that a compile just finished.
  let buffer = "";
  sass.stdout.on("data", (chunk) => {
    process.stdout.write(chunk);
    buffer += chunk.toString();
    const lines = buffer.split("\n");
    buffer = lines.pop();
    if (lines.some((line) => line.startsWith("Compiled "))) fixFontAwesomeUrls();
  });
} else {
  sass.on("exit", (code) => {
    if (code !== 0) process.exit(code);
    fixFontAwesomeUrls();
  });
}
