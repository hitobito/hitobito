# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

namespace :wagon do
  namespace :patches do
    desc "Consolidate patches from all wagons, call from core directory"
    task consolidate: :environment do
      Patches::Collector.new.write
    end

    desc "Generates patches from wagon, call from wagon directory"
    task generate: :environment do
      Rails.application.eager_load!
      Patches::Generator.new.write
    end

    desc "Check patches in wagon, call from wagon directory"
    task check: :environment do
      Rails.application.eager_load!
      Patches::Check.new.run
    end
  end

  namespace :migrate do
    desc "Display status of migrations including the originating wagon name"
    task status: :environment do
      migrations_paths = wagons.each_with_object({}) do |wagon, hash|
        hash[wagon.wagon_name] = wagon.migrations_paths
      end
      migrations_paths["core"] = Rails.application.paths["db/migrate"].to_a
      wagon_names_width = migrations_paths.keys.map(&:length).max

      context = ActiveRecord::MigrationContext.new(migrations_paths.values.flatten,
        ActiveRecord::SchemaMigration)

      context.migrations_status.each do |status, version, name|
        migration_file = context.migrations.find { |m| m.version == version.to_i }&.filename

        if migration_file.nil?
          puts "#{status.center(wagon_names_width)} [#{"???".center(8)}] #{version.ljust(14)}  #{name}"
          next
        end

        wagon_name = migrations_paths
          .find { |_, paths| paths.any? { |p| migration_file.start_with?(p) } }
          &.first

        puts "#{status.center(wagon_names_width)} [#{wagon_name.center(8)}] " \
          "#{version.ljust(14)}  #{name}"
      end
    end
  end

  desc "Dump schema and schema diff for loaded wagons"
  task schema_dump: :environment do
    wagon = Wagons.find(ENV["WAGON"]) || Wagons.all.first
    next unless wagon
    schema = wagon.root.join("db/schema.rb")
    puts "Dumping #{wagon.wagon_name} schema to #{schema}"
    ENV["SCHEMA"] = schema.to_s
    diff = wagon.root.join("db/schema.rb.diff")
    Rake::Task["db:schema:dump"].invoke
    system("diff -W 300 -y #{Rails.root.join("db", "schema.rb")} #{schema} > #{diff}")
  end
end

Rake::Task["wagon:migrate"].enhance do
  Rake::Task["wagon:schema_dump"].execute unless Rails.env.production?
  SearchColumnBuilder.new.run
end
