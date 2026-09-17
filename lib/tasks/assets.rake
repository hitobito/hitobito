#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Writes JSON manifests describing every *active* wagon (Wagons.all) for the two
# Node build scripts - both are prerequisites of css:build/javascript:build,
# which cssbundling-rails and jsbundling-rails in turn hook into
# assets:precompile and spec:prepare.
#
# The compiled output lives in a subdirectory per instance, i.e. per wagon
# composition (see WagonAssetsHelper.instance_name and
# config/initializers/assets.rb).

namespace :assets do
  wagon_css_manifest_path = "tmp/wagon_css_manifest.json"
  wagon_js_manifest_path = "tmp/wagon_js_manifest.json"

  desc "Write the active wagons' stylesheet directories for build_css.mjs, which passes them to" \
    " dart-sass as --load-paths and scans them for the wagons' own entrypoints"
  task wagon_css_manifest: :environment do
    FileUtils.mkdir_p(File.dirname(wagon_css_manifest_path))

    stylesheet_paths = Wagons.all.filter_map do |wagon|
      path = wagon.paths.path.join("app", "assets", "stylesheets")
      path.to_s if path.exist?
    end

    payload = {
      buildDir: WagonAssetsHelper.instance_name,
      wagonStylesheetPaths: stylesheet_paths
    }
    File.write(wagon_css_manifest_path, JSON.pretty_generate(payload))
  end

  desc "Write the active wagons' JS-relevant asset files for esbuild.mjs"
  task wagon_js_manifest: :environment do
    FileUtils.mkdir_p(File.dirname(wagon_js_manifest_path))

    wagons = Wagons.all.map do |wagon|
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

    payload = {buildDir: WagonAssetsHelper.instance_name, wagons: wagons}
    File.write(wagon_js_manifest_path, JSON.pretty_generate(payload))
  end

  if Rake::Task.task_defined?("css:build")
    Rake::Task["css:build"].enhance(["assets:wagon_css_manifest"])
  end

  if Rake::Task.task_defined?("javascript:build")
    Rake::Task["javascript:build"].enhance(["assets:wagon_js_manifest"])
  end

  desc "Build the assets the test environment needs"
  task :build_for_test do
    # The core loads no wagons under RAILS_ENV=test (see Wagonfile.development),
    # so its test instance - and with it the build directory - is a different one
    # than in development. db:test:prepare itself runs in the development
    # environment, hence the subprocess.
    if ENV["RAILS_ENV"] == "test"
      Rake::Task["assets:build"].invoke
    else
      sh({"RAILS_ENV" => "test"}, "bundle exec rake assets:build")
    end
  end

  # cssbundling-rails/jsbundling-rails hook their builds into the first of
  # test:prepare/spec:prepare/db:test:prepare that exists, which here is
  # spec:prepare - so `rake spec:*` builds, but `bin/rails db:test:prepare` (the
  # documented way to prepare a spec run) would not.
  if Rake::Task.task_defined?("db:test:prepare") && !ENV["SKIP_CSS_BUILD"] && !ENV["SKIP_JS_BUILD"]
    Rake::Task["db:test:prepare"].enhance(["assets:build_for_test"])
  end

  desc "Build CSS and JS for the currently active wagon composition, e.g. after" \
    " `bin/active_wagon` switched WAGONS"
  task build: ["css:build", "javascript:build"]

  desc "Rebuild the JS on every change (used by the Procfile and the docker dev setup)"
  task watch_js: ["assets:wagon_js_manifest"] do
    sh "yarn build --watch"
  end

  desc "Rebuild the CSS on every change (used by the Procfile and the docker dev setup)"
  task watch_css: ["assets:wagon_css_manifest"] do
    sh "yarn build:css --watch"
  end
end
