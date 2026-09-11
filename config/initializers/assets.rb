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
