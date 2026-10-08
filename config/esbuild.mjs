// Copyright (c) 2026, hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// Bundles the entrypoints - every .js in app/javascript/entrypoints, plus the
// ones the active wagons bring along (js.json, written by
// `rake assets:wagon_js_manifest`).

import esbuild from "esbuild";
import { globSync } from "glob";
import coffeescript from "coffeescript";
import fs from "fs";
import path from "path";
import { readWagonManifest } from "./wagon_manifest.mjs";

const { buildDir, wagons } = readWagonManifest("js.json");

// Output goes to a subdirectory per wagon composition (see
// config/initializers/assets.rb), so switching wagons, or running specs from a
// wagon's own directory, doesn't clobber a valid build.
const OUTPUT_DIR = path.join("app/assets/builds", buildDir);

const coffeePlugin = {
  name: "coffeescript",
  setup(build) {
    build.onLoad({ filter: /\.coffee$/ }, (args) => {
      const contents = coffeescript.compile(fs.readFileSync(args.path, "utf8"), { bare: true });
      return { contents, loader: "js" };
    });
  },
};

// Stimulus identifier convention: path relative to the controllers root,
// `_controller.js` stripped, underscores->dashes per segment, joined with "--"
// - e.g. events/question_template_nested_form_controller.js becomes
// "events--question-template-nested-form".
function controllerIdentifier(controllersRoot, filePath, wagonName) {
  const relative = path.relative(controllersRoot, filePath).replace(/_controller\.js$/, "");
  const base = relative.split(path.sep).map((segment) => segment.replace(/_/g, "-")).join("--");
  if (!wagonName) return base;
  return `${wagonName.replace(/^hitobito_/, "").replace(/_/g, "-")}--${base}`;
}

// esbuild resolves imports statically, so everything that used to be collected
// at runtime is assembled into explicit import lists first, on every build.
// They are served as in-memory modules under app/javascript/generated/, so
// concurrent builds for different compositions share no files.
const generateImportListsPlugin = {
  name: "generate-import-lists",
  setup(build) {
    const generated = {};

    build.onStart(() => {
      generated["wagon_scripts.js"] = wagons
        .filter((wagon) => wagon.wagonScript)
        .map((wagon) => `import ${JSON.stringify(wagon.wagonScript)};`)
        .join("\n");

      generated["core_modules.js"] = globSync("app/javascript/modules/**/*.{js,coffee}")
        .map((file) => `import ${JSON.stringify(path.resolve(file))};`)
        .join("\n");

      const controllers = [
        ...globSync("app/javascript/controllers/**/*_controller.js").map((file) => ({
          file: path.resolve(file),
          identifier: controllerIdentifier(path.resolve("app/javascript/controllers"), path.resolve(file)),
        })),
        ...globSync("app/components/**/*_controller.js").map((file) => ({
          file: path.resolve(file),
          identifier: controllerIdentifier(path.resolve("app/components"), path.resolve(file)),
        })),
        ...wagons.flatMap((wagon) =>
          wagon.controllers.map((file) => ({
            file,
            identifier: controllerIdentifier(wagon.controllersRoot, file, wagon.name),
          }))
        ),
      ];

      generated["controllers.js"] = `${controllers.map(({ file }, i) => `import Controller${i} from ${JSON.stringify(file)};`).join("\n")}

export function registerGeneratedControllers(application) {
${controllers.map(({ identifier }, i) => `  application.register(${JSON.stringify(identifier)}, Controller${i});`).join("\n")}
}`;
    });

    build.onResolve({ filter: /\/generated\/[a-z_]+$/ }, (args) => ({
      path: `${path.basename(args.path)}.js`,
      namespace: "generated",
    }));

    build.onLoad({ filter: /.*/, namespace: "generated" }, (args) => ({
      contents: generated[args.path],
      loader: "js",
      resolveDir: path.resolve("app/javascript"),
    }));
  },
};

const buildOptions = {
  entryPoints: [
    ...globSync("app/javascript/entrypoints/*.js"),
    ...wagons.flatMap((wagon) => wagon.entrypoints),
  ],
  bundle: true,
  outdir: OUTPUT_DIR,
  // Wagons (siblings of core, not descendants) have no node_modules of their
  // own and can't reach core's via esbuild's normal upward search - nodePaths
  // adds it as an extra lookup root.
  nodePaths: [path.resolve("node_modules")],
  plugins: [coffeePlugin, generateImportListsPlugin],
  loader: { ".woff": "file", ".woff2": "file", ".ttf": "file", ".eot": "file", ".svg": "file" },
  sourcemap: true,
  minify: process.env.NODE_ENV === "production",
  logLevel: "info",
};

if (process.argv.includes("--watch")) {
  esbuild
    .context(buildOptions)
    .then((ctx) => ctx.watch())
    .catch(() => process.exit(1));
} else {
  esbuild.build(buildOptions).catch(() => process.exit(1));
}
