# frozen_string_literal: true

module Hitobito
  class DynamicJavaScriptsGenerator
    def run
      dir = ensure_dir_presence
      create_gems_file(dir.join('gems.js'))
      create_wagons_file(dir.join('wagons.js'))
    end

    private

    def ensure_dir_presence
      dynamic_dir = Rails.root.join('app', 'javascript', 'dynamic')
      dynamic_dir.mkdir unless dynamic_dir.exist?
      dynamic_dir
    end

    def create_gems_file(filename)
      filename.open('w') do |f|
        f.write("// Import the scripts of legacy Gems\n")
        gem_scripts.each { |gem_script| f.write("import \"#{gem_script}\";\n") }
      end
    end

    def create_wagons_file(filename)
      filename.open('w') do |f|
        f.write("// Import the wagon specific scripts\n")
        Wagons.all.each do |wagon|
          wagon_script = File.join(wagon.paths.path.to_s,
                                   'app', 'assets', 'javascripts', 'wagon.js.coffee')
          if File.exist?(wagon_script)
            f.write("import \"#{wagon_script}\"")
          end
        end
      end
    end

    # rubocop:disable Metrics/MethodLength
    def gem_scripts
      [
        gem_file_path(
          'nested_form',
          File.join('vendor', 'assets', 'javascripts', 'jquery_nested_form.js')
        ),
        gem_file_path(
          'remotipart',
          File.join('vendor', 'assets', 'javascripts', 'jquery.iframe-transport.js')
        ),
        gem_file_path(
          'remotipart',
          File.join('vendor', 'assets', 'javascripts', 'jquery.remotipart.js')
        )
      ]
    end
    # rubocop:enable Metrics/MethodLength

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
  end
end

namespace :javascript do
  desc 'Generate the dynamic JavaScript files that require Rails context'
  task generate_dynamic_files: [:environment] do
    Hitobito::DynamicJavaScriptsGenerator.new.run
  end
end
