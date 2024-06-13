#!/usr/bin/env node
const coffeeScriptPlugin = require("esbuild-coffeescript");
const esbuild = require("esbuild");

const options = {
  entryPoints: ["app/javascript/*.*"],
  bundle: true,
  sourcemap: true,
  format: "esm",
  outdir: "app/assets/builds",
  publicPath: "/assets",
  plugins: [coffeeScriptPlugin()],
  logLevel: "info"
};

function build() {
  esbuild.build(options);
}

async function watch() {
  const context = await esbuild.context(options);
  await context.watch();
}

try {
  build();

  if (process.argv.includes("--watch")) {
    watch();
  }
} catch {
  process.exit(1);
}
