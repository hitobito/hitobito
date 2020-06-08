# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# requires transifex-client system package
# rubocop:disable Rails/RakeEnvironment
namespace :tx do
  desc 'Configure locale files for transifex'
  task :config do
    Dir.glob(File.join('config', 'locales', '*.de.yml')).each do |file|
      resource = File.basename(file)[/^(.+)\.de\.yml$/, 1]
      slug = resource.gsub(/\W/, '-')
      gemspec = Dir.glob('*.gemspec').first
      project = gemspec ? gemspec[/^(.+)\.gemspec$/, 1] : 'hitobito'

      sh %W[tx set --auto-local
            -r #{project}.#{slug}
            'config/locales/#{resource}.<lang>.yml'
            --source-lang de
            --execute].join(' ')
    end
  end

  desc 'Init a wagon to use transifex'
  task :init do
    sh 'tx init'
    sh 'tx set -t YML'
  end

  desc 'Push source files (=german locales) to transifex'
  task :push do
    with_tx { sh 'tx push -s' }
  end

  desc 'Pull translations from transifex'
  task :pull do
    # force pull because git locale file timestamps
    # will be newer than transifex files during rpm build.
    with_tx { sh 'tx pull -f' }
  end

  # desc 'Save transifex credentials from env into .transifexrc'
  task :auth do
    username = ENV['RAILS_TRANSIFEX_USERNAME']
    password = ENV['RAILS_TRANSIFEX_PASSWORD']
    if username && password
      host = ENV['RAILS_TRANSIFEX_HOST'] || 'https://www.transifex.com'
      rc = ["[#{host}]",
            "hostname = #{host}",
            "password = #{password}",
            'token =',
            "username = #{username}"].join("\n")
      File.open('.transifexrc', 'w') { |f| f.puts rc }
    else
      puts 'No username and password given'
    end
  end

  def with_tx
    if File.exist?('.tx')
      yield
    else
      puts 'Transifex not configured. Please run rake tx:init first'
    end
  end

  namespace :wagon do
    task :pull do
      ENV['CMD'] = 'if [ -f .tx/config ]; then tx pull -f; fi'
      Rake::Task['wagon:exec'].invoke
    end
    task :push do
      ENV['CMD'] = 'if [ -f .tx/config ]; then tx push -s; fi'
      Rake::Task['wagon:exec'].invoke
    end
  end
end
# rubocop:enable Rails/RakeEnvironment
