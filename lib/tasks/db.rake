# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

desc "Load the mysql database configuration for the following tasks"
task :mysql do
  ENV['RAILS_DB_ADAPTER']  = 'mysql2'
  ENV['RAILS_DB_NAME']     = 'hitobito_test'
  ENV['RAILS_DB_PASSWORD'] = 'root'
  ENV['RAILS_DB_SOCKET']   = '/var/run/mysqld/mysqld.sock'
end
