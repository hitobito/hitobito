#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# The node build scripts in config/ learn the wagons to include from a JSON manifest per
# composition, i.e. per wagon composition, in tmp/wagon_manifests/<composition>/, handed to them as
# WAGON_MANIFEST_DIR. They compile into app/assets/builds/<composition>.
#
# yarn always runs in the core directory, so these tasks also work from a wagon directory,
# where they carry the app: prefix.

namespace :assets do
  css_manifest = lambda do |wagons, composition|
    stylesheet_paths = wagons.filter_map do |wagon|
      path = wagon.paths.path.join("app", "assets", "stylesheets")
      path.to_s if path.exist?
    end

    {buildDir: composition, wagonStylesheetPaths: stylesheet_paths}
  end

  js_manifest = lambda do |wagons, composition|
    wagon_entries = wagons.map do |wagon|
      wagon_root = wagon.paths.path
      controllers_dir = wagon_root.join("app", "javascript", "controllers")
      wagon_script = wagon_root.join("app", "assets", "javascripts", "wagon.js.coffee")

      {
        name: wagon.wagon_name,
        controllersRoot: controllers_dir.to_s,
        entrypoints: Dir[wagon_root.join("app", "javascript", "entrypoints", "*.js")],
        controllers: Dir[controllers_dir.join("**", "*_controller.js")],
        wagonScript: wagon_script.exist? ? wagon_script.to_s : nil
      }
    end

    {buildDir: composition, wagons: wagon_entries}
  end

  write_manifests = lambda do |wagons|
    composition = WagonAssetsHelper.composition(wagons)
    dir = Rails.root.join("tmp", "wagon_manifests", composition)
    dir.mkpath
    ENV["WAGON_MANIFEST_DIR"] = dir.to_s
    dir.join("css.json").write(JSON.pretty_generate(css_manifest.call(wagons, composition)))
    dir.join("js.json").write(JSON.pretty_generate(js_manifest.call(wagons, composition)))
  end

  yarn = ->(*args) { sh("yarn", *args, chdir: Rails.root.to_s) }

  yarn_build = lambda do
    yarn.call("install") unless ENV["SKIP_YARN_INSTALL"]
    yarn.call("build:css") unless ENV["SKIP_CSS_BUILD"]
    yarn.call("build") unless ENV["SKIP_JS_BUILD"]
  end

  # Core specs run without wagons, a wagon's specs with the wagon and its dependencies.
  spec_wagons = -> { Wagons.current_wagon ? Wagons.all : [] }

  desc "Write the manifests of the active wagon composition for the node build scripts"
  task wagon_manifests: :environment do
    write_manifests.call(Wagons.all)
  end

  desc "Build CSS and JS for the active wagon composition"
  task build: :wagon_manifests do
    yarn_build.call
  end

  desc "Build CSS and JS for the composition the specs of this directory run against"
  task build_for_test: :environment do
    write_manifests.call(spec_wagons.call)
    yarn_build.call
  end

  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].enhance(["assets:build"])
  end

  if Rake::Task.task_defined?("assets:clobber")
    Rake::Task["assets:clobber"].enhance do
      rm_rf Dir[Rails.root.join("app", "assets", "builds", "*")]
    end
  end

  if Rake::Task.task_defined?("db:test:prepare") && !(ENV["SKIP_CSS_BUILD"] && ENV["SKIP_JS_BUILD"])
    build_for_test = Rake.application.current_scope.path_with_task_name("build_for_test")
    Rake::Task["db:test:prepare"].enhance { Rake::Task[build_for_test].invoke }
  end

  desc "Rebuild the JS on every change"
  task watch_js: :wagon_manifests do
    yarn.call("build", "--watch")
  end

  desc "Rebuild the CSS on every change"
  task watch_css: :wagon_manifests do
    yarn.call("build:css", "--watch")
  end
end
