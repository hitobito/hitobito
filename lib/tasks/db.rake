# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

desc 'Load the mysql database configuration for the following tasks'
task :mysql do
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
      begin
        group.send(:move_to_alphabetic_position)
        bar.increment
      rescue => e
        puts e
        puts group
      end
    end
    puts 'Done.'
  end
end
