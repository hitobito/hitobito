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

const { execFileSync } = require("child_process");
const { sync: globSync } = require("glob");
const fs = require("fs");
const path = require("path");

const GENERATED_SCSS_DIR = "app/assets/stylesheets_generated";
const OUTPUT_DIR = "app/assets/builds";

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

execFileSync("npx", ["sass", ...args], { stdio: "inherit" });

// @fortawesome/fontawesome-free's own CSS assumes it's served one directory
// below its webfonts/ (as it is within the npm package itself: css/all.css
// next to ../webfonts/), so it hardcodes `url(../webfonts/...)`. Our
// compiled CSS lives at the root of app/assets/builds instead, so - same as
// our own font/image url()s (see app/javascript/stylesheets/hitobito/
// customizable/_fonts.scss) - that has to become a bare, root-relative
// filename for Propshaft::Compiler::CssAssetUrls to resolve it, matching
// the flat node_modules/@fortawesome/fontawesome-free/webfonts path
// registered in config/initializers/assets.rb.
for (const output of outputs) {
  if (!fs.existsSync(output)) continue;
  const content = fs.readFileSync(output, "utf8");
  const fixed = content.replace(/url\((['"]?)\.\.\/webfonts\//g, "url($1");
  if (fixed !== content) fs.writeFileSync(output, fixed);
}
