#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Renders the ERB-based SCSS entrypoints (see WagonAssetsHelper) into plain
# .scss files dart-sass can compile, and writes JSON manifests describing every
# *active* wagon (Wagons.all) for the two Node build scripts - all of them are
# prerequisites of css:build/javascript:build, which cssbundling-rails and
# jsbundling-rails in turn hook into assets:precompile and test:prepare.
#
# The compiled output and the SCSS rendered here both live in a subdirectory per
# instance, i.e. per wagon composition (see WagonAssetsHelper.instance_name and
# config/initializers/assets.rb).

namespace :assets do
  generated_scss_dir = "app/assets/stylesheets_generated"
  wagon_manifest_path = "tmp/wagon_assets_manifest.json"
  wagon_scss_load_paths_path = "tmp/wagon_scss_load_paths.json"

  # WagonAssetsHelper is an autoloaded app/helpers constant, only resolvable
  # once :environment has booted the app - hence a lambda, not a constant.
  scss_renderer = lambda do
    Class.new do
      include ActionView::Helpers
      include WagonAssetsHelper

      # wagon_path is what an entrypoint refers its own files to: the wagon it
      # belongs to, or Rails.root for the core's own entrypoints.
      attr_accessor :wagon_path

      def render(source_path)
        ERB.new(File.read(source_path)).result(binding)
      end
    end.new
  end

  desc "Render the ERB-based SCSS entrypoints (core + wagon-owned) into plain .scss files"
  task render_scss_entries: :environment do
    renderer = scss_renderer.call

    scoped_dir = File.join(generated_scss_dir, WagonAssetsHelper.instance_name)
    FileUtils.mkdir_p(scoped_dir)

    entries = Dir[Rails.root.join("app", "assets", "stylesheets", "*.scss.erb")]
      .to_h { |source_path| [source_path, Rails.root] }
    # Wagons.all is a plain Array, not an ActiveRecord::Relation - find_each doesn't apply.
    # rubocop:disable Rails/FindEach
    Wagons.all.each do |wagon|
      Dir[wagon.paths.path.join("app", "assets", "stylesheets", "*.scss.erb")].each do |source_path|
        entries[source_path] = wagon.paths.path
      end
    end
    # rubocop:enable Rails/FindEach

    entries.each do |source_path, wagon_path|
      renderer.wagon_path = wagon_path
      target_name = File.basename(source_path, ".erb")
      File.write(File.join(scoped_dir, target_name), renderer.render(source_path))
    end
  end

  desc "Write each active wagon's root directory, so build_css.mjs can pass it to dart-sass" \
    " as an extra --load-path"
  task wagon_scss_load_paths: :environment do
    FileUtils.mkdir_p(File.dirname(wagon_scss_load_paths_path))

    # dart-sass resolves the entries' absolute-path wagon @imports fine on its
    # own, but --watch only monitors directories reachable via a --load-path
    # root - passing each wagon's root as an extra one (in build_css.mjs) fixes
    # that without changing import resolution itself.
    payload = {
      buildDir: WagonAssetsHelper.instance_name,
      wagonRoots: Wagons.all.map { |wagon| wagon.paths.path.to_s }
    }
    File.write(wagon_scss_load_paths_path, JSON.pretty_generate(payload))
  end

  desc "Write a manifest of the active wagons' JS-relevant asset files for the esbuild build script"
  task wagon_js_manifest: :environment do
    FileUtils.mkdir_p(File.dirname(wagon_manifest_path))

    wagons = Wagons.all.map do |wagon|
      wagon_root = wagon.paths.path
      controllers_dir = wagon_root.join("app", "javascript", "controllers")
      wagon_script = wagon_root.join("app", "assets", "javascripts", "wagon.js.coffee")

      {
        name: wagon.wagon_name,
        controllersRoot: controllers_dir.to_s,
        entrypoints: Dir[wagon_root.join("app", "javascript", "*.js")],
        controllers: Dir[controllers_dir.join("**", "*_controller.js")],
        wagonScript: wagon_script.exist? ? wagon_script.to_s : nil
      }
    end

    payload = {buildDir: WagonAssetsHelper.instance_name, wagons: wagons}
    File.write(wagon_manifest_path, JSON.pretty_generate(payload))
  end

  if Rake::Task.task_defined?("css:build")
    Rake::Task["css:build"].enhance(["assets:render_scss_entries", "assets:wagon_scss_load_paths"])
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
  task watch_css: ["assets:render_scss_entries", "assets:wagon_scss_load_paths"] do
    sh "yarn build:css --watch"
  end
end
