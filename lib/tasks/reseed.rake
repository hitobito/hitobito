
namespace :db do

  desc "Empties the database and loads the seeds again"
  task :reseed => ['db:clobber', 'db:schema:load', 'db:seed', 'wagon:seed']

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

  desc "Completely empties the database"
  task :clobber => :environment do
    con = ActiveRecord::Base.connection
    ActiveRecord::Base.transaction do
      con.tables.each do |t|
        con.drop_table(t)
      end
    end
  end
end