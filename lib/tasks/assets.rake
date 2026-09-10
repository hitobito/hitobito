#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Renders the ERB-based SCSS entrypoints (which need access to `Settings` and
# to each *active* wagon's customizable variables/fonts, see WebpackHelper)
# into plain .scss files that dart-sass can compile, and writes a JSON
# manifest describing the JavaScript-relevant files of every *active* wagon
# (Wagons.all - i.e. the wagons Bundler actually loaded for this app, not
# just whatever hitobito_* directories happen to be checked out next to
# core) for the esbuild build script to consume.
#
# Both are prerequisites of cssbundling-rails' `css:build` / jsbundling-rails'
# `javascript:build`, which are themselves wired into `assets:precompile` and
# `test:prepare`.

namespace :assets do
  GENERATED_SCSS_DIR = "app/assets/stylesheets_generated"
  WAGON_MANIFEST_PATH = "tmp/wagon_assets_manifest.json"

  desc "Render ERB-based SCSS entrypoints (core + wagon-owned) into plain .scss files"
  task render_scss_entries: :environment do
    # WebpackHelper is an autoloaded app/helpers constant, only resolvable
    # once :environment has booted the app - defined here, not at file load.
    renderer_class = Class.new do
      include ActionView::Helpers
      include WebpackHelper

      def render(source_path)
        ERB.new(File.read(source_path)).result(binding)
      end
    end
    renderer = renderer_class.new

    FileUtils.mkdir_p(GENERATED_SCSS_DIR)

    entries = Dir[Rails.root.join("app", "javascript", "packs", "*.scss.erb")]
    Wagons.all.each do |wagon|
      entries += Dir[wagon.paths.path.join("app", "javascript", "packs", "*.scss.erb")]
    end

    target_names = entries.map { |source_path| File.basename(source_path, ".erb") }

    # Prune entries left over from a *different* wagon (switching WAGONS and
    # recompiling would otherwise keep e.g. a previous wagon's agenda.scss
    # around forever, since we only ever write/overwrite here, never clean up).
    (Dir[File.join(GENERATED_SCSS_DIR, "*.scss")].map { |f| File.basename(f) } - target_names).each do |stale|
      File.delete(File.join(GENERATED_SCSS_DIR, stale))
    end

    entries.each do |source_path|
      target_name = File.basename(source_path, ".erb")
      target_path = File.join(GENERATED_SCSS_DIR, target_name)
      File.write(target_path, renderer.render(source_path))
    end
  end
  Rake::Task["css:build"].enhance(["assets:render_scss_entries"]) if Rake::Task.task_defined?("css:build")

  desc "Render ERB-based JS entrypoints (e.g. gem-provided assets without an npm package) into plain .js files"
  task render_js_entries: :environment do
    renderer_class = Class.new do
      include ActionView::Helpers
      include WebpackHelper

      def render(source_path)
        ERB.new(File.read(source_path)).result(binding)
      end
    end
    renderer = renderer_class.new

    generated_dir = "app/javascript/generated"
    FileUtils.mkdir_p(generated_dir)

    Dir[Rails.root.join("app", "javascript", "javascripts", "vendor", "*.js.erb")].each do |source_path|
      target_name = File.basename(source_path, ".erb")
      File.write(File.join(generated_dir, target_name), renderer.render(source_path))
    end
  end
  Rake::Task["javascript:build"].enhance(["assets:render_js_entries"]) if Rake::Task.task_defined?("javascript:build")

  desc "Write a manifest of active wagons' JS-relevant asset files for the esbuild build script"
  task wagon_js_manifest: :environment do
    FileUtils.mkdir_p(File.dirname(WAGON_MANIFEST_PATH))

    wagons = Wagons.all.map do |wagon|
      wagon_root = wagon.paths.path
      wagon_script = wagon_root.join("app", "assets", "javascripts", "wagon.js.coffee")

      {
        name: wagon.wagon_name,
        controllersRoot: wagon_root.join("app", "javascript", "controllers").to_s,
        packs: Dir[wagon_root.join("app", "javascript", "packs", "*.js")],
        controllers: Dir[wagon_root.join("app", "javascript", "controllers", "**", "*_controller.js")],
        wagonScript: wagon_script.exist? ? wagon_script.to_s : nil
      }
    end

    File.write(WAGON_MANIFEST_PATH, JSON.pretty_generate(wagons))
  end
  Rake::Task["javascript:build"].enhance(["assets:wagon_js_manifest"]) if Rake::Task.task_defined?("javascript:build")
end
