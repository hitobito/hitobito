# frozen_string_literal: true

namespace :assets do
  task precompile: [:environment] do
    Rake::Task['assets:rewrite_css_urls'].invoke
  end

  desc 'Rewrite the url() local paths in the public/assets/*.css files and include asset hash'
  task rewrite_css_urls: [:environment] do
    css_files.each { |file| rewrite_urls(file) }
  end

  def css_files
    Dir[Rails.public_path.join('assets', '*.css')]
  end

  def rewrite_urls(css_file)
    css = File.read(css_file)

    css
      # Every local URL, excluding data URIs & http(s)
      .scan(/url\(['"]?(?!data|http)([^'"\)]+)['"]?\)/)
      .collect { |url| url.first }
      .each do |url|
        new_url = rewrite_url(url)
        css.sub!(url, new_url) if new_url
      end

    File.write(css_file, css)
  end

  def rewrite_url(url)
    file = find_asset_file(url)

    unless file
      puts "Warning: Cannot find file for #{url} in public/assets directory" unless file
      return nil
    end

    "/assets/#{File.basename(file)}"
  end

  def find_asset_file(url)
    basename = File.basename(url, '.*')
                   # Strip hashes from already hashed files
                   .sub(/-[a-z0-9]{64}$/, '')
    extension = File.extname(url)
                    # Ignore any hash (#) or query (?) parts after the extension
                    .sub(/^\.([^?#]+)(.*)/, '\1')

    asset_files(extension).find do |f|
      f.match(/\/#{basename}-[a-z0-9]{64}.#{extension}$/)
    end
  end

  def asset_files(extension)
    Dir[Rails.public_path.join('assets', "*.#{extension}")]
  end
end
