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
#
# Compiled output (app/assets/builds) and the SCSS rendered here
# (app/assets/stylesheets_generated) are both split into a subdirectory per
# "wagon signature" (see WebpackHelper.wagon_signature) - see
# config/initializers/assets.rb for why (and why current_wagon-based
# anchoring, which would have been simpler, doesn't work: bin/wagon spec
# always runs the build itself from core's own directory, only the final
# rspec process actually runs from inside the wagon).

namespace :assets do
  generated_scss_dir = "app/assets/stylesheets_generated"
  wagon_manifest_path = "tmp/wagon_assets_manifest.json"
  wagon_scss_load_paths_path = "tmp/wagon_scss_load_paths.json"

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

    signature = WebpackHelper.wagon_signature
    scoped_dir = File.join(generated_scss_dir, signature)
    FileUtils.mkdir_p(scoped_dir)

    entries = Dir[Rails.root.join("app", "javascript", "packs", "*.scss.erb")]
    # Wagons.all is a plain Array, not an ActiveRecord::Relation - find_each doesn't apply.
    # rubocop:disable Rails/FindEach
    Wagons.all.each do |wagon|
      entries += Dir[wagon.paths.path.join("app", "javascript", "packs", "*.scss.erb")]
    end
    # rubocop:enable Rails/FindEach

    target_names = entries.map { |source_path| File.basename(source_path, ".erb") }

    # Prune entries left over from a previous build under the *same*
    # signature (e.g. a wagon dropping an extra pack it used to have) - each
    # signature already has its own directory, so this can't happen *across*
    # signatures anymore.
    existing_names = Dir[File.join(scoped_dir, "*.scss")].map { |file| File.basename(file) }
    (existing_names - target_names).each do |stale_name|
      File.delete(File.join(scoped_dir, stale_name))
    end

    entries.each do |source_path|
      target_name = File.basename(source_path, ".erb")
      target_path = File.join(scoped_dir, target_name)
      File.write(target_path, renderer.render(source_path))
    end
  end

  if Rake::Task.task_defined?("css:build")
    Rake::Task["css:build"].enhance(["assets:render_scss_entries"])
  end

  desc "Write each active wagon's root directory, so build_css.js can pass it to dart-sass" \
    " as an extra --load-path"
  task wagon_scss_load_paths: :environment do
    FileUtils.mkdir_p(File.dirname(wagon_scss_load_paths_path))

    signature = WebpackHelper.wagon_signature

    # The rendered entries @import a wagon's customizable _variables.scss/
    # _fonts.scss/_wagon.scss via an absolute path (see WebpackHelper's
    # absolute_wagon_file_paths), which dart-sass resolves and compiles fine
    # on its own - but in --watch mode it only watches directories reachable
    # through one of its --load-path roots, never an arbitrary absolute
    # @import target outside of them. Passing each wagon's own root as an
    # extra --load-path (build_css.js) fixes that, without changing import
    # resolution itself since the imports are already absolute.
    wagon_roots = Wagons.all.map { |wagon| wagon.paths.path.to_s }
    payload = {signature: signature, wagonRoots: wagon_roots}
    File.write(wagon_scss_load_paths_path, JSON.pretty_generate(payload))
  end

  if Rake::Task.task_defined?("css:build")
    Rake::Task["css:build"].enhance(["assets:wagon_scss_load_paths"])
  end

  desc "Render ERB-based JS entrypoints (gem assets with no npm package) into plain .js files"
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

    vendor_dir = Rails.root.join("app", "javascript", "javascripts", "vendor")
    Dir[vendor_dir.join("*.js.erb")].each do |source_path|
      target_name = File.basename(source_path, ".erb")
      File.write(File.join(generated_dir, target_name), renderer.render(source_path))
    end
  end

  if Rake::Task.task_defined?("javascript:build")
    Rake::Task["javascript:build"].enhance(["assets:render_js_entries"])
  end

  desc "Write a manifest of active wagons' JS-relevant asset files for the esbuild build script"
  task wagon_js_manifest: :environment do
    FileUtils.mkdir_p(File.dirname(wagon_manifest_path))

    signature = WebpackHelper.wagon_signature

    wagons = Wagons.all.map do |wagon|
      wagon_root = wagon.paths.path
      controllers_dir = wagon_root.join("app", "javascript", "controllers")
      wagon_script = wagon_root.join("app", "assets", "javascripts", "wagon.js.coffee")

      {
        name: wagon.wagon_name,
        controllersRoot: controllers_dir.to_s,
        packs: Dir[wagon_root.join("app", "javascript", "packs", "*.js")],
        controllers: Dir[controllers_dir.join("**", "*_controller.js")],
        wagonScript: wagon_script.exist? ? wagon_script.to_s : nil
      }
    end

    payload = {signature: signature, wagons: wagons}
    File.write(wagon_manifest_path, JSON.pretty_generate(payload))
  end

  if Rake::Task.task_defined?("javascript:build")
    Rake::Task["javascript:build"].enhance(["assets:wagon_js_manifest"])
  end
end
