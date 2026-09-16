#  Copyright (c) 2020, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module WagonAssetsHelper
  # The wagon composition this application is running as, e.g. "sac_cas-youth"
  # for WAGONS="sac_cas youth", or "core" without any wagon. Keys the compiled
  # asset output (app/assets/builds/<instance>, see lib/tasks/assets.rake and
  # config/initializers/assets.rb) - a single source of truth so Ruby and the
  # JS build scripts can't drift apart.
  def self.instance_name
    Wagons.all.map(&:wagon_name).sort.join("-").presence || "core"
  end

  # Prioritizes wagon images: config/initializers/assets.rb registers active
  # wagons' app/assets/images before core's, so a wagon can override a core
  # asset using the same file name.
  def wagon_image_path(name)
    image_path(name)
  end

  # Renders an image tag, preferring a wagon's image (see wagon_image_path).
  def wagon_image_tag(name, **options)
    if options[:srcset] && !options[:srcset].is_a?(String)
      options[:srcset] = options[:srcset].map do |src_name, size|
        "#{wagon_image_path(src_name)} #{size}"
      end.join(", ")
    end

    image_tag(wagon_image_path(name), options)
  end

  # Renders a favicon tag, preferring a wagon's favicon (see wagon_image_path).
  def wagon_favicon_tag(name, **options)
    favicon_link_tag(wagon_image_path(name), options)
  end

  # Yields the path of every wagon's file at relative_wagon_file_path, or
  # fallback_file_path if no wagon has one.
  #
  # Example:
  #   absolute_wagon_file_paths(
  #     File.join('app', 'assets', 'stylesheets', 'customizable', '_fonts.scss'),
  #     Rails.root.join('app', 'assets', 'stylesheets', 'customizable', '_fonts.scss')
  #   ) do |file_path|
  #     # Do something...
  #   end
  def absolute_wagon_file_paths(relative_wagon_file_path, fallback_file_path = nil)
    file_paths =
      Wagons
        .all
        .collect { |wagon| File.join(wagon.paths.path.to_s, relative_wagon_file_path) }
        .select { |file_path| File.exist?(file_path) }
        .each { |file_path| yield(file_path) }

    if fallback_file_path && file_paths.blank?
      yield(fallback_file_path)
    end
  end
end
