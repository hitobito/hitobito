# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

desc 'Load the mysql database configuration for the following tasks'
task :mysql do # rubocop:disable Rails/RakeEnvironment
  ENV['RAILS_DB_ADAPTER']   = 'mysql2'
  ENV['RAILS_DB_NAME']      = 'hitobito_development'
  ENV['RAILS_TEST_DB_NAME'] = 'hitobito_test'
  ENV['RAILS_DB_PASSWORD']  = 'root'
  ENV['RAILS_DB_SOCKET']    = '/var/run/mysqld/mysqld.sock'
end

namespace :db do
  desc 'Rebuild Nested-Set'
  task rebuild_nested_set: [:environment] do
    puts 'Rebuilding nested set...'
    Group.update_all(lft: nil, rgt: nil) # rubocop:disable Rails/SkipsModelValidations
    Group.rebuild!(false)
    puts 'Done.'
  end

  desc 'Move Groups in alphabetical order'
  task resort_groups: [:environment] do
    puts 'Moving Groups in alphabetical order...'

    bar = begin
      require 'ruby-progressbar'
      ProgressBar.create(format: '%a |%w>%i| %c/%C | %E ', total: Group.count)
    rescue LoadError
      Class.new { def increment; end }.new
    end

    Group.find_each do |group|
      group.send(:move_to_alphabetic_position)
      bar.increment
    rescue => e
      puts e
      puts group
    end
    puts 'Done.'
  end

  desc 'Import a dump and run migrations'
  task :import, [:backup_filename] do |_t, args| # rubocop:disable Rails/RakeEnvironment
    args.with_defaults(backup_filename: 'tmp/backup.sql.gz')
    backup = Pathname.new(args[:backup_filename]).expand_path

    cat = if backup.extname == '.gz'
            if Gem::Platform.local.os == 'darwin'
              'gunzip -c'
            else # we assume Linux
              'zcat'
            end
          else # we assume SQL in a text/plain file
            'cat'
          end


    # some things are more stable and understandable when expressed as a shell-command
    sh 'rails db:drop db:create'
    sh "#{cat} #{backup} | rails db -p"

    # other things are straightforward rake-tasks
    Rake::Task['db:migrate'].invoke
    Rake::Task['wagon:migrate'].invoke

    ENV['NO_ENV'] = "1"
    Rake::Task['db:seed'].invoke
    Rake::Task['wagon:seed'].invoke
  end
end
