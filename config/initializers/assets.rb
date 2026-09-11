# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

wagon_image_paths = Wagons.all.filter_map do |wagon|
  wagon_images_path = wagon.paths.path.join("app", "assets", "images")
  wagon_images_path.to_s if wagon_images_path.exist?
end

wagon_font_paths = Wagons.all.filter_map do |wagon|
  wagon_fonts_path = wagon.paths.path.join("app", "assets", "fonts")
  wagon_fonts_path.to_s if wagon_fonts_path.exist?
end

Rails.application.config.assets.paths += wagon_image_paths
Rails.application.config.assets.paths += wagon_font_paths
Rails.application.config.assets.paths << Rails.root.join("app", "javascript", "images").to_s
Rails.application.config.assets.paths << Rails.root.join("app", "javascript", "fonts").to_s

# @fortawesome/fontawesome-free's webfonts, referenced (as bare filenames,
# see build_css.js) from its own CSS's @font-face rules.
Rails.application.config.assets.paths << Rails.root.join("node_modules", "@fortawesome", "fontawesome-free", "webfonts").to_s

# Propshaft's own `config.after_initialize` (registered before this
# initializer runs) prioritizes any path under Rails.root over paths outside
# of it - which, in local/sibling-wagon development, would always rank core's
# app/javascript/images *above* every wagon's app/assets/images (and fonts),
# since only in the vendor/wagons production layout do wagon paths live
# under Rails.root. We want the opposite: a wagon's file should win over a
# core file of the same name (e.g. favicon.ico, logo.png) in every layout -
# mirrors the previous wagon-media/media priority in
# config/webpack/loaders/wagon-file.js. Reordering again in our own
# after_initialize (registered later, so it runs after Propshaft's) lets us
# override that default.
Rails.application.config.after_initialize do |app|
  wagon_paths_set = (wagon_image_paths + wagon_font_paths).to_set
  wagon_paths, other_paths = app.config.assets.paths.partition { |path| wagon_paths_set.include?(path.to_s) }
  app.config.assets.paths = wagon_paths + other_paths
end

unless Rails.env.production?
  require_relative "../../lib/wagon_asset_naming"
  wagon = WagonAssetNaming.primary_wagon_name
  Rails.application.config.assets.prefix = "/assets-#{wagon.dasherize}"

  # Each wagon gets its own JS/CSS build output directory (see
  # lib/tasks/assets.rake's assets:primary_wagon task and esbuild.config.js/
  # build_css.js) so switching which wagon you're running specs/dev-server
  # for never clobbers another wagon's already-built assets. This has to
  # happen in after_initialize, same as the wagon_paths reordering above:
  # the main app's own "propshaft.append_assets_path" (which auto-registers
  # every app/assets/builds* directory that exists on disk, including the
  # plain, pre-per-wagon-split app/assets/builds) runs *after* this
  # initializer file, not before, so filtering here directly would silently
  # miss everything it adds.
  Rails.application.config.after_initialize do |app|
    builds_path = Rails.root.join("app", "assets", "builds-#{wagon}").to_s
    stale_builds_paths = Dir[Rails.root.join("app", "assets", "builds*")] - [builds_path]

    app.config.assets.paths.reject! { |path| stale_builds_paths.include?(path.to_s) }
    app.config.assets.paths << builds_path unless app.config.assets.paths.map(&:to_s).include?(builds_path)
  end
end
