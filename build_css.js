// Copyright (c) 2026, hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// Compiles every entry rendered by `rake assets:render_scss_entries`
// (core's application/oauth/print + any wagon-owned *.scss packs, e.g.
// hitobito_sac_cas's agenda.scss) via dart-sass. `--load-path=.` lets these
// entries `@import` core files with a plain `app/javascript/...` path,
// mirroring how the wagon-owned `@import`s (emitted as absolute file
// paths by WebpackHelper#absolute_wagon_file_paths) already resolve.

const { execFileSync, spawn } = require("child_process");
const { sync: globSync } = require("glob");
const fs = require("fs");
const path = require("path");

const GENERATED_SCSS_DIR = "app/assets/stylesheets_generated";
const WAGON_LOAD_PATHS_PATH = "tmp/wagon_scss_load_paths.json";
const OUTPUT_DIR = "app/assets/builds";
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

const wagonLoadPaths = fs.existsSync(WAGON_LOAD_PATHS_PATH)
  ? JSON.parse(fs.readFileSync(WAGON_LOAD_PATHS_PATH, "utf8"))
  : [];

const entries = globSync(`${GENERATED_SCSS_DIR}/*.scss`);

if (entries.length === 0) {
  console.error(`No .scss entries found in ${GENERATED_SCSS_DIR} - did "rake assets:render_scss_entries" run?`);
  process.exit(1);
}

const outputs = entries.map((entry) => path.join(OUTPUT_DIR, `${path.basename(entry, ".scss")}.css`));

// Prune stale CSS outputs left over from a *different* wagon (e.g. a
// previous wagon's agenda.css, when the newly active one has no such pack)
// - only touches *.css (we compile with --no-source-map), so this can't
// clobber the JS build's own outputs.
const outputBasenames = new Set(outputs.map((o) => path.basename(o)));
for (const existing of globSync(`${OUTPUT_DIR}/*.css`)) {
  if (!outputBasenames.has(path.basename(existing))) fs.unlinkSync(existing);
}

const args = [
  ...entries.map((entry, i) => `${entry}:${outputs[i]}`),
  "--load-path=node_modules",
  "--load-path=.",
  // Purely for dart-sass's own --watch to also monitor these directories -
  // the entries' wagon @imports are already absolute paths, resolved fine
  // without this, but --watch never notices a change to a file outside of
  // its --load-path roots (see assets:wagon_scss_load_paths).
  ...wagonLoadPaths.map((wagonRoot) => `--load-path=${wagonRoot}`),
  "--no-source-map",
  "--style=compressed",
  ...process.argv.slice(2), // e.g. --watch, forwarded from `yarn build:css --watch`
];

// @fortawesome/fontawesome-free's own CSS assumes it's served one directory
// below its webfonts/ (as it is within the npm package itself: css/all.css
// next to ../webfonts/), so it hardcodes `url(../webfonts/...)`. Our
// compiled CSS lives at the root of app/assets/builds instead, so - same as
// our own font/image url()s (see app/javascript/stylesheets/hitobito/
// customizable/_fonts.scss) - that has to become a bare, root-relative
// filename for Propshaft::Compiler::CssAssetUrls to resolve it, matching
// the flat node_modules/@fortawesome/fontawesome-free/webfonts path
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
  // In one-shot mode we can just wait for `sass` to exit before running the
  // fix-up once. In --watch mode `sass` never exits (it's a long-running
  // process, see Procfile), so the fix-up must run after *every*
  // recompilation instead - triggered by watching its own stdout, since
  // that's the only signal dart-sass's CLI gives for "a compile just
  // finished".
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
