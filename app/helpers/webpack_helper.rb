# encoding: utf-8

#  Copyright (c) 2020, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module WebpackHelper
  # Returns the path of a given image as provided by Webpack
  # (e.g. `/packs/images/myimage.png`). Prioritizes wagon images, if
  # available. This makes it possible for wagons to "override" core
  # assets with the same file name.
  def wagon_image_pack_path(name)
    wagon_path = Webpacker.instance.manifest.lookup(wagon_media_image_path(name))
    if wagon_path
      path_to_asset(wagon_path)
    else
      resolve_path_to_image(name)
    end
  end

  # Similar to Webpacker's `image_pack_tag` helper, but renders image
  # from wagons if available
  def wagon_image_pack_tag(name, **options)
    if options[:srcset] && !options[:srcset].is_a?(String)
      options[:srcset] = options[:srcset].map do |src_name, size|
        "#{wagon_image_pack_path(src_name)} #{size}"
      end.join(", ")
    end

    image_tag(wagon_image_pack_path(name), options)
  end

  # Similar to Webpacker's `favicon_pack_tag` helper, but renders
  # favicon from wagons if available
  def wagon_favicon_pack_tag(name, **options)
    favicon_link_tag(wagon_image_pack_path(name), options)
  end

  # Returns the absolute path of a file within a specific gem.
  #
  # Example:
  #   gem_file_path(
  #     'nested_form',
  #     File.join('vendor', 'assets', 'javascripts', 'jquery_nested_form.js')
  #   )
  def gem_file_path(gem_name, relative_file_path)
    raise "Gem '#{gem_name}' not present" unless Gem.loaded_specs[gem_name]

    File.join(Gem.loaded_specs[gem_name].full_gem_path, relative_file_path)
  end

  # Yields the file path for every wagon that contains a file at
  # `relative_file_path`. The optional `fallback_file_path` is yielded,
  # if no wagon contains a file at `relative_file_path`.
  #
  # Example:
  #   absolute_wagon_file_paths(
  #     File.join('app', 'assets', 'stylesheets', 'customizable', '_fonts.scss'),
  #     File.join('app', 'assets', 'stylesheets', 'customizable', '_fonts.scss')
  #   ) do |file_path|
  #     # Do something...
  #   end
  def absolute_wagon_file_paths(relative_wagon_file_path, fallback_file_path = nil)
    file_paths = \
      Wagons
      .all
      .collect { |wagon| File.join(wagon.paths.path.to_s, relative_wagon_file_path) }
      .select { |file_path| File.exist?(file_path) }
      .each { |file_path| yield(file_path) }

    if fallback_file_path && file_paths.blank?
      yield(fallback_file_path)
    end
  end

  private

  def wagon_media_image_path(file_name)
    File.join("wagon-media", "images", file_name)
  end
end
