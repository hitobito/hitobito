# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :db do

  desc "Empties the database and loads the seeds again"
  task reseed: ["db:clobber", "db:schema:load", "db:seed", "wagon:seed"]

  desc "Deletes all data from the database, but keeps the tables"
  task truncate: :environment do
    con = ActiveRecord::Base.connection
    tables = con.tables - %w(schema_migrations delayed_jobs)
    ActiveRecord::Base.transaction do
      tables.each do |t|
        con.execute("DELETE FROM #{t}")
      end
    end
  end

  desc "Completely empties the database"
  task clobber: :environment do
    con = ActiveRecord::Base.connection
    ActiveRecord::Base.transaction do
      con.tables.each do |t|
        con.drop_table(t)
      end
    end
  end
end
