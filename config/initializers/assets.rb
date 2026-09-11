# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

wagon_asset_paths = lambda do |subdir|
  Wagons.all.filter_map do |wagon|
    path = wagon.paths.path.join("app", "assets", subdir)
    path.to_s if path.exist?
  end
end

wagon_image_paths = wagon_asset_paths.call("images")
wagon_font_paths = wagon_asset_paths.call("fonts")

Rails.application.config.assets.paths += wagon_image_paths
Rails.application.config.assets.paths += wagon_font_paths
Rails.application.config.assets.paths << Rails.root.join("app", "javascript", "images").to_s
Rails.application.config.assets.paths << Rails.root.join("app", "javascript", "fonts").to_s

# @fortawesome/fontawesome-free's webfonts, referenced (as bare filenames,
# see build_css.js) from its own CSS's @font-face rules.
Rails.application.config.assets.paths << Rails.root.join("node_modules", "@fortawesome",
  "fontawesome-free", "webfonts").to_s

# Compiled assets are split into a subdirectory per "wagon signature" (see
# WebpackHelper.wagon_signature, only resolvable inside after_initialize -
# autoloading isn't ready this early). Wagons.current_wagon doesn't work
# for this: it can differ between the process that builds the assets and
# the process that serves them, so build- and serve-time would disagree.
# The bare app/assets/builds directory never holds files itself, so it's
# excluded below in favor of the current signature's own subdirectory.
bare_build_path = Rails.root.join("app", "assets", "builds").to_s

# app/assets/stylesheets_generated is dart-sass's *input*, never served -
# excluded for the same reason and the same way as bare_build_path below.
bare_stylesheets_generated_path = Rails.root.join("app", "assets", "stylesheets_generated").to_s

# Propshaft's own after_initialize (registered earlier) ranks paths under
# Rails.root above outside ones - which would rank core's images above a
# wagon's in local dev (only production's vendor/wagons layout puts wagon
# paths under Rails.root). We want the opposite: a wagon's file should win
# over core's for the same name. Reordering again here (registered later)
# overrides that - and, since Propshaft's own asset-path auto-discovery has
# already run by now, this is also the right place to swap in the
# per-signature build path (setting excluded_paths any earlier is too late).
Rails.application.config.after_initialize do |app|
  signature_build_path = Rails.root.join(
    "app", "assets", "builds", WebpackHelper.wagon_signature
  ).to_s
  excluded_paths = [bare_build_path, bare_stylesheets_generated_path]
  wagon_paths_set = (wagon_image_paths + wagon_font_paths).to_set

  prioritize_wagon_paths = lambda do |paths|
    priority, others = paths.partition { |path| wagon_paths_set.include?(path.to_s) }
    others = others.reject { |path| excluded_paths.include?(path.to_s) }
    priority + [signature_build_path] + others
  end

  app.config.assets.paths = prioritize_wagon_paths.call(app.config.assets.paths)
end
