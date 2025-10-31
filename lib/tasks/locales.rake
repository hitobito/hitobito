namespace :locales do
  desc "Copy german variant locale files to 'de' locale if they exist (e.g., de_CH to de)"
  task :patch_de do
    search_paths = [Rails.root] + Wagons.all.map(&:root)

    search_paths.each do |path|
      locale_dir = path.join("config", "locales")

      # Find all YAML files for de locale variants (e.g., *.de_CH.yml)
      locale_dir.glob("*.de_??.yml").each do |source_file|
        source_locale = source_file.to_s[/(de_..)\.yml$/, 1]

        # Read the source file and replace the locale key (e.g., 'de_CH:') with 'de:'
        i18n_data = source_file.read.sub(/^#{source_locale}:/, "de:")

        # Write the modified content to the file with the 'de' locale suffix
        target_file = source_file.to_s.sub(".#{source_locale}.yml", ".de.yml")
        puts "Writing patched #{source_file} to #{target_file}"
        File.write(target_file, i18n_data)
      end
    end
  end
end
