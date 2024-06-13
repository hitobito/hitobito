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
    # TODO: migrate
    return ""
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

  private

  def wagon_media_image_path(file_name)
    File.join("wagon-media", "images", file_name)
  end
end
