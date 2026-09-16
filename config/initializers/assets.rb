# Be sure to restart your server when you modify this file.

require Rails.root.join("lib", "hitobito", "relative_asset_urls")

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

wagon_asset_paths = lambda do |*subdirs|
  Wagons.all.flat_map do |wagon|
    subdirs.map { |subdir| wagon.paths.path.join("app", "assets", subdir) }
  end.select(&:exist?).map(&:to_s)
end

# Propshaft registers every app/assets/* subdirectory of the core and of each
# wagon (wagons are engines) by itself. Some of those hold sources rather than
# servable assets:
#   - app/assets/stylesheets is dart-sass' input (core's and the wagons')
#   - app/assets/stylesheets_generated is the ERB-rendered input (see
#     lib/tasks/assets.rake)
#   - app/assets/javascripts is esbuild's input (wagons only)
#   - the bare app/assets/builds never holds files itself, and leaving it
#     registered would make Propshaft::LoadPath#dedup drop the per-instance
#     subdirectory nested inside it, which is the one we actually serve
Rails.application.config.assets.excluded_paths += [
  Rails.root.join("app", "assets", "stylesheets").to_s,
  Rails.root.join("app", "assets", "stylesheets_generated").to_s,
  Rails.root.join("app", "assets", "builds").to_s,
  *wagon_asset_paths.call("stylesheets", "javascripts")
]

# @fortawesome/fontawesome-free's webfonts, referenced from its own CSS's
# @font-face rules (as ../webfonts/..., normalized by RelativeAssetUrls below).
Rails.application.config.assets.paths << Rails.root.join("node_modules", "@fortawesome",
  "fontawesome-free", "webfonts").to_s

# Must run before propshaft's own CssAssetUrls, which resolves what we normalize.
Rails.application.config.assets.compilers.unshift(["text/css", Hitobito::RelativeAssetUrls])

# Compiled assets live in a subdirectory per instance (see
# WagonAssetsHelper.instance_name, only resolvable inside after_initialize -
# autoloading isn't ready this early). Wagons.current_wagon doesn't work for
# this: running specs from a wagon's directory sets a different BUNDLE_GEMFILE
# and therefore a different current_wagon for the very same composition.
Rails.application.config.after_initialize do |app|
  # Override propshaft's asset load order so our wagons can override the core's
  # assets. The first registered path wins (Propshaft::LoadPath#assets_by_path
  # maps with ||=), so with several wagons the first one in Wagons.all order does.
  wagon_paths = wagon_asset_paths.call("images", "fonts").to_set
  build_path = Rails.root.join("app", "assets", "builds",
    WagonAssetsHelper.instance_name).to_s

  priority, others = app.config.assets.paths.partition { |path| wagon_paths.include?(path.to_s) }
  app.config.assets.paths = priority + [build_path] + others
end
