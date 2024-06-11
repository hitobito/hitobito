# frozen_string_literal: true

require "#{Rails.root}/app/helpers/webpack_helper"
include WebpackHelper

namespace :css do
  desc 'Generate the dynamic wagon-specific SCSS files'
  task generate_dynamic_files: [:environment] do
    dir = ensure_dir_presence
    create_base_vars_file(dir.join('base_variables.sass.scss'))
    create_wagons_vars_file(dir.join('wagons_variables.sass.scss'))
    create_wagons_fonts_file(dir.join('wagons_fonts.sass.scss'))
    create_wagons_styles_file(dir.join('wagons_styles.sass.scss'))
  end

  def ensure_dir_presence
    styles_dir = Rails.root.join('app', 'assets', 'stylesheets')
    styles_dir.mkdir unless styles_dir.exist?

    dynamic_dir = styles_dir.join('dynamic')
    dynamic_dir.mkdir unless dynamic_dir.exist?
    dynamic_dir
  end

  def create_base_vars_file(filename)
    filename.open('w') do |f|
      f.write(
        "// Logo & background settings (from settings.yml)\n" \
        "$logo-width: #{logo_width}px !default;\n" \
        "$logo-height: #{logo_height}px !default;\n" \
        "$logo-background-color: #{logo_bg} !default;\n" \
        "#{page_background ? "$page-background: #{page_background};\n" : ''}"
      )
    end
  end

  def create_wagons_vars_file(filename)
    create_imports_file(
      filename,
      'Import the wagons\' specific variables or fall back to core variables',
      File.join('app', 'assets', 'stylesheets', 'hitobito', 'customizable', '_variables.scss'),
      File.join('..', 'hitobito', 'customizable', '_variables.scss')
    )
  end

  def create_wagons_fonts_file(filename)
    create_imports_file(
      filename,
      'Import the wagons\' fonts or fall back to core fonts',
      File.join('app', 'assets', 'stylesheets', 'hitobito', 'customizable', '_fonts.scss'),
      File.join('..', 'hitobito', 'customizable', '_fonts.scss')
    )
  end

  def create_wagons_styles_file(filename)
    create_imports_file(
      filename,
      'Import the wagons\' styles',
      File.join('app', 'assets', 'stylesheets', 'hitobito', 'customizable', '_wagon.scss')
    )
  end

  def create_imports_file(filename, description, wagon_scss_file, fallback_scss_file = nil)
    filename.open('w') do |f|
      absolute_wagon_file_paths(wagon_scss_file, fallback_scss_file) do |file_path|
        f.write(
          "// #{description}\n" \
          "@import \"#{file_path}\";\n"
        )
      end
    end
  end

  def logo_width
    Settings.application.logo.width
  end

  def logo_height
    Settings.application.logo.height
  end

  def logo_bg
    Settings.application.logo.background_color
  end

  def page_background
    environment = ENV['RAILS_HOST_NAME'] || 'dev'
    Settings.application.page_background.try(environment)
  end
end
