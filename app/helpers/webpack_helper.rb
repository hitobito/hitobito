#  Copyright (c) 2020, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module WebpackHelper
  # hitobito_youth has no assets of its own and is always paired with a
  # "real" wagon (sac_cas+youth, pbs+youth, ...), so it must not affect the
  # signature - otherwise sac_cas+youth and sac_cas-alone would get
  # different signatures for an asset-identical build.
  SIGNATURE_IGNORED_WAGONS = %w[youth].freeze

  # Keys compiled asset output (app/assets/builds/<signature>, see
  # lib/tasks/assets.rake and config/initializers/assets.rb) - a single
  # source of truth so Ruby and the JS build scripts can't drift apart.
  def self.wagon_signature
    names = Wagons.all.map(&:wagon_name) - SIGNATURE_IGNORED_WAGONS
    names.sort.join("-").presence || "core"
  end

  # Prioritizes wagon images: config/initializers/assets.rb registers active
  # wagons' app/assets/images before core's, so a wagon can override a core
  # asset using the same file name.
  def wagon_image_pack_path(name)
    image_path(name)
  end

  # Renders an image tag, preferring a wagon's image (see wagon_image_pack_path).
  def wagon_image_pack_tag(name, **options)
    if options[:srcset] && !options[:srcset].is_a?(String)
      options[:srcset] = options[:srcset].map do |src_name, size|
        "#{wagon_image_pack_path(src_name)} #{size}"
      end.join(", ")
    end

    image_tag(wagon_image_pack_path(name), options)
  end

  # Renders a favicon tag, preferring a wagon's favicon (see wagon_image_pack_path).
  def wagon_favicon_pack_tag(name, **options)
    favicon_link_tag(wagon_image_pack_path(name), options)
  end

  # Absolute path of a file within a gem - for JS/CSS gem assets with no npm
  # package equivalent (see lib/tasks/assets.rake's render_js_entries).
  #
  # Example:
  #   gem_file_path(
  #     'remotipart',
  #     File.join('vendor', 'assets', 'javascripts', 'jquery.iframe-transport.js')
  #   )
  def gem_file_path(gem_name, relative_file_path)
    raise "Gem '#{gem_name}' not present" unless Gem.loaded_specs[gem_name]

    File.join(Gem.loaded_specs[gem_name].full_gem_path, relative_file_path)
  end

  # Yields the path of every wagon's file at relative_wagon_file_path, or
  # fallback_file_path if no wagon has one.
  #
  # Example:
  #   absolute_wagon_file_paths(
  #     File.join('app', 'assets', 'stylesheets', 'customizable', '_fonts.scss'),
  #     File.join('app', 'assets', 'stylesheets', 'customizable', '_fonts.scss')
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
