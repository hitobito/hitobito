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
Rails.application.config.assets.paths << Rails.root.join("node_modules", "@fortawesome",
  "fontawesome-free", "webfonts").to_s

# Compiled assets (app/assets/builds) are split into a subdirectory per
# "wagon signature" - Wagons.all's sorted wagon names, or "core" when none -
# see lib/tasks/assets.rake, build_css.js and esbuild.config.js, which all
# write there using the exact same computation. This is what lets switching
# which wagon(s) are active - or running specs from a wagon's own directory
# via bin/wagon spec, which always builds from core's own directory first
# (Wagons.current_wagon is *not* usable here: it would only reflect "inside
# a wagon" for the later rspec process itself, not the build step that
# precedes it) - avoid clobbering a previous, still-valid build. The bare
# app/assets/builds directory itself never holds files directly (only
# per-signature subdirectories), so it's excluded below in favor of
# registering only the current signature's own subdirectory.
wagon_signature = Wagons.all.map(&:wagon_name).sort.join("-")
wagon_signature = "core" if wagon_signature.empty?
signature_build_path = Rails.root.join("app", "assets", "builds", wagon_signature).to_s
bare_build_path = Rails.root.join("app", "assets", "builds").to_s

# app/assets/stylesheets_generated is dart-sass's *input*, never served -
# excluded for the same reason and the same way as bare_build_path below.
bare_stylesheets_generated_path = Rails.root.join("app", "assets", "stylesheets_generated").to_s

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
# override that default - and, for the same "runs after Propshaft's own
# per-engine registration" reason, is also where we swap the bare
# app/assets/builds for our per-signature subdirectory (setting
# excluded_paths here instead would be too late: Propshaft's "propshaft.
# append_assets_path" engine initializer, which does the actual app/assets/*
# auto-discovery, has already run and applied excluded_paths as it stood at
# that point by the time this app-level initializer gets to run).
Rails.application.config.after_initialize do |app|
  wagon_paths_set = (wagon_image_paths + wagon_font_paths).to_set
  wagon_paths, other_paths = app.config.assets.paths.partition { |path|
    wagon_paths_set.include?(path.to_s)
  }
  other_paths = other_paths.reject do |path|
    [bare_build_path, bare_stylesheets_generated_path].include?(path.to_s)
  end
  app.config.assets.paths = wagon_paths + [signature_build_path] + other_paths
end
