# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Licenser
  FORMATS = {
    rb:   '#  ',
    rake: '#  ',
    yml:  '#  ',
    haml: '-#  ',
    coffee: '#  ',
    scss: '//  '
  }

  EXCLUDES = %w(
    db/schema.rb
    config/boot.rb
    config/environment.rb
    config/locales/devise.de.yml
    config/initializers/backtrace_silencers.rb
    config/initializers/devise.rb
    config/initializers/inflections.rb
    config/initializers/mime_types.rb
    config/initializers/session_store.rb
    config/initializers/wrap_parameters.rb
  )

  ENCODING_EXTENSIONS = [:rb, :rake]
  ENCODING_STRING     = '# encoding: utf-8'
  ENCODING_PATTERN    = /#\s*encoding: utf-8/i


  def initialize(project_name, copyright_holder, copyright_source)
    @project_name = project_name
    @copyright_holder = copyright_holder
    @copyright_source = copyright_source
  end

  def preamble_text
    @preamble_text ||= <<-END.strip
Copyright (c) 2012-#{Time.now.year}, #{@copyright_holder}. This file is part of
#{@project_name} and licensed under the Affero General Public License version 3
or later. See the COPYING file at the top-level directory or at
#{@copyright_source}.
END
  end

  def insert
    each_file do |content, format|
      unless format.has_preamble?(content)
        insert_preamble(content, format)
      end
    end
  end

  def update
    each_file do |content, format|
      if format.has_preamble?(content)
        content = remove_preamble(content, format)
      end
      insert_preamble(content, format)
    end
  end

  def remove
    each_file do |content, format|
      if format.has_preamble?(content)
        remove_preamble(content, format)
      end
    end
  end

  private

  def insert_preamble(content, format)
    if format.file_with_encoding? && content.strip =~ /\A#{ENCODING_PATTERN}/i
      content.gsub!(/\A#{ENCODING_PATTERN}\s*/mi, '')
    end
    format.preamble + content
  end

  def remove_preamble(content, format)
    content.gsub!(/\A#{format.copyright_pattern}.*$/, '')
    while (content.start_with?("\n#{format.comment}"))
      content.gsub!(/\A\n#{format.comment}\s+.*$/, '')
    end
    content.gsub!(/\A\s*\n/, '')
    content.gsub!(/\A\s*\n/, '')
    if format.file_with_encoding?
      content = ENCODING_STRING + "\n\n" + content
    end
    content
  end

  def each_file
    FORMATS.each do |extension, prefix|
      format = Format.new(extension, prefix, preamble_text)

      Dir.glob("**/*.#{extension}").each do |file|
        unless EXCLUDES.include?(file)
          content = yield File.read(file), format
          if content
            puts file
            File.open(file, 'w') { |f| f.print content }
          end
        end
      end
    end
  end

  class Format
    attr_reader :extension, :prefix, :copyright_pattern, :preamble

    def initialize(extension, prefix, preamble_text)
      @extension = extension
      @prefix = prefix
      @preamble = preamble_text.each_line.collect { |l| prefix + l }.join + "\n\n"
      @copyright_pattern = /#{prefix.strip}\s+Copyright/
      if file_with_encoding?
        @preamble = "#{ENCODING_STRING}\n\n" + @preamble
        @copyright_pattern = /#{ENCODING_PATTERN}\n\n+#{@copyright_pattern}/
      end
    end

    def file_with_encoding?
      ENCODING_EXTENSIONS.include?(extension)
    end

    def has_preamble?(content)
      content.strip =~ /\A#{copyright_pattern}/
    end

    def comment
      @comment ||= prefix.strip
    end

  end
end


namespace :license do
  task :config do
    @licenser = Licenser.new('hitobito',
                             'Jungwacht Blauring Schweiz',
                             'https://github.com/hitobito/hitobito')
  end

  desc 'Insert the license preamble in all source files'
  task :insert => :config do
    @licenser.insert
  end

  desc 'Update or insert the license preamble in all source files'
  task :update => :config do
    @licenser.update
  end

  desc 'Remove the license preamble from all source files'
  task :remove => :config do
    @licenser.remove
  end
end