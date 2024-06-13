# frozen_string_literal: true

module Hitobito
  class CssUrlsRewriter
    def run
      css_files.each { |file| rewrite_urls(file) }
    end

    private

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
      files = find_asset_files(url)

      if files.empty?
        log_asset_not_found_warning(url)
        return nil
      end

      if files.length > 1
        # Is this possible, when a wagon has a file name equally like a file in core?
        log_multiple_assets_error(url, matches.length)
        raise
      end

      "/assets/#{File.basename(files.first)}"
    end

    def find_asset_files(url)
      basename = File.basename(url, '.*')
                     # Strip hashes from already hashed files
                     .sub(/-[a-z0-9]{64}$/, '')
      extension = File.extname(url)
                      # Ignore any query (?) or hash (#) parts after the extension
                      .sub(/^\.([^?#]+)(.*)/, '\1')

      asset_files(extension).select do |f|
        f.match(/\/#{basename}-[a-z0-9]{64}.#{extension}$/)
      end
    end

    def asset_files(extension)
      Dir[Rails.public_path.join('assets', "*.#{extension}")]
    end

    def log_asset_not_found_warning(url)
      Rails.logger.warn("Warning: Cannot find file for #{url} in public/assets directory")
    end

    def log_multiple_assets_error(url, count)
      Rails.logger.error(
        "Error: Found #{count} files for #{url} in public/assets directory"
      )
    end
  end
end

namespace :assets do
  task precompile: [:environment] do
    Rake::Task['assets:rewrite_css_urls'].invoke
  end

  desc 'Rewrite the url() local paths in the public/assets/*.css files and include asset hash'
  task rewrite_css_urls: [:environment] do
    Hitobito::CssUrlsRewriter.new.run
  end
end
