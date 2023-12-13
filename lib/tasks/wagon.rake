# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

namespace :wagon do
  namespace :migrate do
    desc 'Display status of migrations including the originating wagon name'
    task status: :environment do
      migrations_paths = wagons.each_with_object({}) do |wagon, hash|
        hash[wagon.wagon_name] = wagon.migrations_paths
      end
      migrations_paths['core'] = Rails.application.paths['db/migrate'].to_a
      wagon_names_width = migrations_paths.keys.map(&:length).max

      context = ActiveRecord::MigrationContext.new(migrations_paths.values.flatten,
                                                   ActiveRecord::SchemaMigration)

      context.migrations_status.each do |status, version, name|
        migration_file = context.migrations.find {|m| m.version == version.to_i }.filename
        wagon_name = migrations_paths.
          find {|_, paths| paths.any? {|p| migration_file.start_with?(p) } }&.
          first

        puts "#{status.center(wagon_names_width)} [#{wagon_name.center(8)}] " \
          "#{version.ljust(14)}  #{name}"
      end
    end
  end
end
