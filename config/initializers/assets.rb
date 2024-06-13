# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w(print.css ie.css ie7.css wysiwyg.css wysiwyg.js *.png *.gif *.jpg favicon.ico)

# CSS entry files
Rails.application.config.assets.precompile += %w(print.css oauth.css membership_verify.js)

# Fonts
Rails.application.config.assets.precompile += %w(*.woff2 *.woff *.ttf *.svg *.eot)

# Wagons assets
wagons_paths = Wagons.all.collect { |wagon| wagon.paths.path.to_s }
wagon_images = wagons_paths.collect { |wagon_path| File.join(wagon_path, 'app', 'assets', 'images') }
wagon_fonts = wagons_paths.collect { |wagon_path| File.join(wagon_path, 'app', 'assets', 'fonts') }

Rails.application.config.assets.precompile += wagon_images
Rails.application.config.assets.precompile += wagon_fonts
