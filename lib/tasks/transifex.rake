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
    if Dir.glob('.tx/config').size > 0
      sh "tx push -s"
    else
      puts 'Transifex not configured'
    end
  end

  desc 'Pull the configured languages from transifex'
  task :pull => :environment do
    if Dir.glob('.tx/config').size > 0
      langs = Settings.application.languages.to_hash.keys.join(',')
      sh "tx pull -l #{langs}"
    else
      puts 'Transifex not configured'
    end
  end
end