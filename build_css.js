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
const PRIMARY_WAGON_PATH = "tmp/primary_wagon.txt";
const watch = process.argv.includes("--watch");

// `rake assets:render_scss_entries assets:primary_wagon` (which pulls in the
// *active* wagon's _variables.scss/_fonts.scss/_wagon.scss via WebpackHelper,
// and names this boot's primary wagon) is wired as a prerequisite of the Rake
// task `css:build`, but this script also runs directly via `yarn build:css`
// (e.g. the Procfile's `css` process in normal dev mode) - a plain
// `yarn`/`node` invocation never goes through Rake at all, so those steps
// need to run here too, or switching WAGONS would silently keep serving
// whichever wagon was last rendered.
execFileSync("bundle", ["exec", "rake", "assets:render_scss_entries", "assets:primary_wagon"], { stdio: "inherit" });

// Each wagon builds into its own directory (blank/production falls back to
// the plain, shared app/assets/builds) so switching which wagon you're
// running specs or the dev server for never clobbers another wagon's
// already-built output - see config/initializers/assets.rb.
const primaryWagon = fs.existsSync(PRIMARY_WAGON_PATH) ? fs.readFileSync(PRIMARY_WAGON_PATH, "utf8").trim() : "";
const OUTPUT_DIR = primaryWagon ? `app/assets/builds-${primaryWagon}` : "app/assets/builds";
fs.mkdirSync(OUTPUT_DIR, { recursive: true });

const entries = globSync(`${GENERATED_SCSS_DIR}/*.scss`);

if (entries.length === 0) {
  console.error(`No .scss entries found in ${GENERATED_SCSS_DIR} - did "rake assets:render_scss_entries" run?`);
  process.exit(1);
}

const outputs = entries.map((entry) => path.join(OUTPUT_DIR, `${path.basename(entry, ".scss")}.css`));

const args = [
  ...entries.map((entry, i) => `${entry}:${outputs[i]}`),
  "--load-path=node_modules",
  "--load-path=.",
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
