# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# requires transifex-client system package
namespace :tx do
  desc 'Configure locale files for transifex'
  task :config do
    Dir.glob(File.join('config', 'locales', '*.de.yml')).each do |file|
      resource = File.basename(file)[/^(.+)\.de\.yml$/, 1]
      slug = resource.gsub(/\W/, '-')
      gemspec = Dir.glob('*.gemspec').first
      project = gemspec ? gemspec[/^(.+)\.gemspec$/, 1] : 'hitobito'

      sh %W(tx set --auto-local
                   -r #{project}.#{slug}
                   'config/locales/#{resource}.<lang>.yml'
                   --source-lang de
                   --execute).join(' ')
    end
  end

  desc 'Init a wagon to use transifex'
  task :init do
    sh 'tx init'
    sh 'tx set -t YML'
  end

  desc 'Push source files (=german locales) to transifex'
  task :push do
    sh "tx push -s"
  end

  desc 'Pull translations from transifex'
  task :pull  do
    sh 'tx pull'
  end

  #desc 'Save transifex credentials from env into .transifexrc'
  task :auth do
    username = ENV['RAILS_TRANSIFEX_USERNAME']
    password = ENV['RAILS_TRANSIFEX_PASSWORD']
    if username && password
      host = ENV['RAILS_TRANSIFEX_HOST'] || 'https://www.transifex.com'
      rc = "[#{host}]\nhostname = #{host}\npassword = #{password}\ntoken =\nusername = #{username}\n"
      File.open('.transifexrc', 'w') { |f| f.puts rc }
    else
      puts 'No username and password given'
    end
  end

  namespace :wagon do
    task :pull do
      ENV['CMD'] = "if [ -f .tx/config ]; then tx pull; fi"
      Rake::Task['wagon:exec'].invoke
    end
  end
end