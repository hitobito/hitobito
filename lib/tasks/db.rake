# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

desc "Load the postgres database configuration for the following tasks"

task :postgres do # rubocop:disable Rails/RakeEnvironment
  ENV["RAILS_DB_ADAPTER"] = "postgres"
  ENV["RAILS_DB_NAME"] = "hitobito_development"
  ENV["RAILS_TEST_DB_NAME"] = "hitobito_test"
  ENV["RAILS_DB_PASSWORD"] = "hitobito"
  ENV["RAILS_DB_SOCKET"] = "/var/run/postgresql/.s.PGSQL.5432"
end

namespace :db do
  task empty_db: :environment do
    # Drop all tables except rails internals
    connection = ActiveRecord::Base.connection
    rails_internal_tables = ["schema_migrations", "ar_internal_metadata"]
    tables_to_delete = connection.tables - rails_internal_tables
    tables_to_delete.each do |table|
      connection.execute("DROP TABLE IF EXISTS #{table} CASCADE")
    end

    # Truncate rails internals
    rails_internal_tables.each do |table|
      connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE")
    end
  end

  task :migrate do # rubocop:disable Rails/RakeEnvironment This task is only extended here and has all needed preconditions set
    Rake::Task["delayed_job:schedule"].invoke
  end

  namespace :migrate do
    desc "Display status of migrations including the originating wagon name"
    task status_all: [:environment] do
      Rake::Task["wagon:migrate:status"].invoke
    end
  end

  desc "Rebuild Nested-Set"
  task rebuild_nested_set: [:environment] do
    puts "Rebuilding nested set..."
    Group.update_all(lft: nil, rgt: nil) # rubocop:disable Rails/SkipsModelValidations
    Group.rebuild!(false)
    puts "Done."
  end

  desc "Move Groups in alphabetical order"
  task resort_groups: [:environment] do
    puts "Moving Groups in alphabetical order..."

    bar = begin
      require "ruby-progressbar"
      ProgressBar.create(format: "%a |%w>%i| %c/%C | %E ", total: Group.count)
    rescue LoadError
      Class.new {
        def increment
        end
      }.new
    end

    Group.find_each do |group|
      group.send(:move_to_alphabetic_position)
      bar.increment
    rescue => e
      puts e
      puts group
    end
    puts "Done."
  end

  desc "Import a dump and run migrations"
  task :import, [:backup_filename] do |_t, args| # rubocop:disable Rails/RakeEnvironment
    args.with_defaults(backup_filename: "tmp/backup.sql.gz")
    backup = Pathname.new(args[:backup_filename]).expand_path
    decompressed = Pathname.new("tmp/decompressed-backup.sql").expand_path

    cat = if backup.extname == ".gz"
      if Gem::Platform.local.os == "darwin"
        "gunzip -c"
      else # we assume Linux
        "zcat"
      end
    else # we assume SQL in a text/plain file
      "cat"
    end

    pv = if `which pv | wc -l`.chomp.to_i.positive?
      "pv" # pipeviewer, `apt install pv`, provides a progressbar
    else
      "cat"
    end

    # some things are more stable and understandable when expressed as a shell-command
    sh "rails db:drop db:create"
    sh "#{cat} #{backup} > #{decompressed}"
    sh "#{pv} #{decompressed} | rails db -p"
    rm decompressed.to_s # output what is done

    # other things are straightforward rake-tasks
    Rake::Task["db:migrate"].invoke
    Rake::Task["wagon:migrate"].invoke

    ENV["NO_ENV"] = "1"
    Rake::Task["db:seed"].invoke
    Rake::Task["wagon:seed"].invoke
  end

  namespace :seed do
    desc "load common seeds, i.e. not tied to a Rails.env"
    task common: [:environment] do
      ENV["NO_ENV"] = "1"
      Rake::Task["db:seed"].invoke
    end

    desc "Load development seed files of a wagon. Example: rake db:seed:development[generic]"
    task :development, [:wagon] => :environment do |t, args|
      args.with_defaults({wagon: "generic"})
      wagon = args[:wagon]

      seed_path = Wagons.find(wagon).root.join("db", "seeds", "development").expand_path

      warn "✅ Seeding development seeds for wagon: #{wagon}"

      Dir[seed_path.join("*.rb")].sort.each do |file|
        warn "→ Seeding: #{File.basename(file)}"
        load file
      end

      warn "🎉 Done seeding #{wagon}."
    end
  end

  namespace :structure do
    desc "Dumps the structure.sql without having to change \
          schema_format in config/application.rb. Used by bin/wagon."
    task dump_sql: :environment do
      ActiveRecord.schema_format = :sql
      Rake::Task["db:schema:dump"].invoke
    end

    desc "Loads the structure.sql without having to change \
          schema_format in config/application.rb. Used by bin/wagon."
    task load_sql: :environment do
      ActiveRecord.schema_format = :sql
      Rake::Task["db:schema:load"].invoke
    end
  end
end
