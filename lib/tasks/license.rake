# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is
#  licensed under the Affero General Public License version 3 or later.
#  See the COPYING file.


namespace :license do
  task :config do
    ENV['COPYRIGHT_HOLDER'] ||= 'Jungwacht Blauring Schweiz'

    ENV['PREAMBLE'] ||= <<-END.strip
Copyright (c) 2012-#{Time.now.year}, #{ENV['COPYRIGHT_HOLDER']}. This file is
part of Hitobito and licensed under the Affero General Public License version 3
or later. See the COPYING file.
END

    FORMATS = {
      rb:   '#  ',
      rake: '#  ',
      yml:  '#  ',
      haml: '-#  ',
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
  end

  desc 'Insert the license preamble in all source files'
  task :insert => :config do
    FORMATS.each do |extension, prefix|
      preamble = ENV['PREAMBLE'].each_line.collect {|l| prefix + l }.join + "\n\n"
      copyright_pattern = /#{prefix.strip}\s+Copyright/
      if [:rb, :rake].include?(extension)
        preamble = "# encoding: utf-8\n\n" + preamble
        copyright_pattern = /# encoding: utf-8\n\n+#{copyright_pattern}/
      end

      Dir.glob("**/*.#{extension}").each do |file|
        unless EXCLUDES.include?(file)
          content = File.read(file)
          unless content.strip =~ /\A#{copyright_pattern}/
            puts file
            if [:rb, :rake].include?(extension) && content.strip =~ /\A#\s*encoding: utf-8/i
              content.gsub!(/\A#\s*encoding: utf-8\s*/mi, '')
            end
            File.open(file, 'w') {|f| f.print preamble + content }
          end
        end
      end
    end
  end
end
