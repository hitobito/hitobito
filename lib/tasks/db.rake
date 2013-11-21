
desc "Load the mysql database configuration for the following tasks"
task :mysql do
  ENV['RAILS_DB_ADAPTER']  = 'mysql2'
  ENV['RAILS_DB_NAME']     = 'hitobito_test'
  ENV['RAILS_DB_PASSWORD'] = 'root'
  ENV['RAILS_DB_SOCKET']   = '/var/run/mysqld/mysqld.sock'
end
