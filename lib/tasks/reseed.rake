
namespace :db do

  desc "Truncates the database and loads the seeds again"
  task :reseed => ['db:truncate', 'db:seed', 'wagon:seed']

  desc "Deletes all data from the database, but keeps the tables"
  task :truncate => :environment do
    con = ActiveRecord::Base.connection
    tables = con.tables - ['schema_migrations', 'delayed_jobs']
    ActiveRecord::Base.transaction do
      tables.each do |t|
        con.execute("DELETE FROM #{t}")
      end
    end
  end

end