#  Copyright (c) 2020, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module WebpackHelper
  # Not a wagon-specific ".youth is shared" ignore list, just this one
  # name: hitobito_youth has no assets of its own (no _variables.scss, no
  # wagon.js.coffee, no packs) and is paired alongside a "real" customer
  # wagon in every composition that uses it (hitobito_sac_cas+youth,
  # hitobito_pbs+youth, hitobito_jubla+youth, ...) - so it never changes
  # what gets compiled. Without excluding it, sac_cas+youth and a
  # hypothetical sac_cas-alone setup would get two different signatures
  # (see #wagon_signature) for a build that's otherwise identical.
  SIGNATURE_IGNORED_WAGONS = %w[youth].freeze

  # The "wagon signature" used to key compiled asset output
  # (app/assets/builds/<signature>, app/assets/stylesheets_generated/
  # <signature>) - see lib/tasks/assets.rake and
  # config/initializers/assets.rb. A single source of truth so the Ruby
  # rake tasks and the app initializer can't drift apart on how it's
  # computed - the two build scripts (build_css.js, esbuild.config.js) read
  # the already-computed value from the manifest JSONs those tasks write,
  # rather than recomputing it themselves.
  def self.wagon_signature
    names = Wagons.all.map(&:wagon_name) - SIGNATURE_IGNORED_WAGONS
    names.sort.join("-").presence || "core"
  end

  # Returns the path of a given image (e.g. `/assets/myimage-abcd1234.png`).
  # Prioritizes wagon images, if available - config/initializers/assets.rb
  # registers every active wagon's app/assets/images directory *before*
  # core's own, so Propshaft's asset lookup naturally resolves a wagon's
  # file first when it shares a name with a core file. This makes it
  # possible for wagons to "override" core assets with the same file name.
  def wagon_image_pack_path(name)
    image_path(name)
  end

  # Renders an image tag, preferring a wagon's image over core's for the
  # same file name (see wagon_image_pack_path).
  def wagon_image_pack_tag(name, **options)
    if options[:srcset] && !options[:srcset].is_a?(String)
      options[:srcset] = options[:srcset].map do |src_name, size|
        "#{wagon_image_pack_path(src_name)} #{size}"
      end.join(", ")
    end

    image_tag(wagon_image_pack_path(name), options)
  end

  # Renders a favicon tag, preferring a wagon's favicon over core's for the
  # same file name (see wagon_image_pack_path).
  def wagon_favicon_pack_tag(name, **options)
    favicon_link_tag(wagon_image_pack_path(name), options)
  end

  # Returns the absolute path of a file within a specific gem.
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
