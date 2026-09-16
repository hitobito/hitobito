// Copyright (c) 2026, hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// Compiles every entrypoint rendered by `rake assets:render_scss_entries`
// (core's application/oauth/print/disable_animations plus the wagon-owned ones,
// e.g. hitobito_sac_cas's agenda.scss) with dart-sass.

import { spawn } from "child_process";
import { globSync } from "glob";
import fs from "fs";
import path from "path";

const WAGON_LOAD_PATHS_PATH = "tmp/wagon_scss_load_paths.json";

const { buildDir, wagonRoots } = JSON.parse(fs.readFileSync(WAGON_LOAD_PATHS_PATH, "utf8"));

// Both the rendered SCSS and the output go to a subdirectory per instance, i.e.
// per wagon composition (see config/initializers/assets.rb), so switching wagons,
// or running specs from a wagon's own directory, doesn't clobber a valid build.
const GENERATED_SCSS_DIR = path.join("app/assets/stylesheets_generated", buildDir);
const OUTPUT_DIR = path.join("app/assets/builds", buildDir);
fs.mkdirSync(OUTPUT_DIR, { recursive: true });

const entries = globSync(`${GENERATED_SCSS_DIR}/*.scss`);

if (entries.length === 0) {
  console.error(`No .scss entries found in ${GENERATED_SCSS_DIR} - did "rake assets:render_scss_entries" run?`);
  process.exit(1);
}

const args = [
  ...entries.map((entry) => `${entry}:${path.join(OUTPUT_DIR, `${path.basename(entry, ".scss")}.css`)}`),
  "--load-path=node_modules",
  // Lets any entrypoint, core's and a wagon's alike, @import a core partial as
  // "hitobito/...". Deliberately not adding the wagons' own stylesheet
  // directories: they have the same internal layout as the core's, so bare
  // imports would become order-dependent. Wagons import their own files by
  // absolute path.
  "--load-path=app/assets/stylesheets",
  // For "app/components/steps_component".
  "--load-path=.",
  // For dart-sass's own --watch to monitor these too - the @imports themselves
  // are absolute paths and already resolve fine without this.
  ...wagonRoots.map((wagonRoot) => `--load-path=${wagonRoot}`),
  "--no-source-map",
  ...(process.env.NODE_ENV === "production" ? ["--style=compressed"] : []),
  ...process.argv.slice(2), // e.g. --watch, forwarded from `yarn build:css --watch`
];

const sass = spawn("npx", ["sass", ...args], { stdio: "inherit" });
sass.on("exit", (code) => process.exit(code ?? 1));
