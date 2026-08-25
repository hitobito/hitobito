# frozen_string_literal: true

#  Copyright (c) 2025-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :locales do
  desc "Copy the configured german variant locale files to the 'de' locale (e.g., de_CH to de)"
  task patch_de: :environment do
    variant = Settings.application.german_variant.presence

    if variant.nil?
      puts "No application.german_variant configured, nothing to patch"
      next
    end

    search_paths = [Rails.root] + Wagons.all.map(&:root)

    search_paths.each do |path|
      locale_dir = path.join("config", "locales")

      # Find all YAML files for the configured de locale variant (e.g., *.de_CH.yml)
      locale_dir.glob("*.#{variant}.yml").each do |source_file|
        # Read the source file and replace the locale key (e.g., 'de_CH:') with 'de:'
        i18n_data = source_file.read.sub(/^#{variant}:/, "de:")

        # Write the modified content to the file with the 'de' locale suffix
        target_file = source_file.to_s.sub(".#{variant}.yml", ".de.yml")
        puts "Writing patched #{source_file} to #{target_file}"
        File.write(target_file, i18n_data)
      end
    end
  end
end
