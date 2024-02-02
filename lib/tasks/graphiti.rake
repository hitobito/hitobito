# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

namespace :graphiti do
  namespace :schema do
    def green(text) = "\033[32m#{text}\033[0m"
    def red(text) = "\033[31m#{text}\033[0m"
    def pretty_schema_path = Graphiti.config.schema_path.relative_path_from(Pathname.pwd.parent)

    task setup: :environment do
      # The rake task can be called in the core directory or in a wagon directory.
      # We need to configure graphiti to use the correct schema.json file.
      # Set the path to the schema.json file relative to the current working directory.
      Graphiti.configure do |config|
        config.schema_path = Pathname.pwd.join('spec', 'support', 'graphiti', 'schema.json')
      end
    end

    desc 'Check if the schema file exists'
    task file_exists: 'graphiti:schema:setup' do
      abort red(<<~MSG) unless File.exist?(Graphiti.config.schema_path)
        Schema file not found: #{pretty_schema_path}

        Run `bundle exec rake graphiti:schema:generate` and commit the file to the git repository.

      MSG

      puts green 'Schema file exists'
    end

    desc 'Check if the schema has incompatible changes'
    task compatible: 'graphiti:schema:setup' do
      message = <<~MSG
        Found backwards-incompatibilities in schema!
        If you are REALLY SURE you want to ignore the incompatiblities,
        run `rake graphiti:schema:overwrite` and commit the resulting file
        #{pretty_schema_path}
        to the git repository.

        Incompatibilities:
      MSG

      errors = Graphiti::Schema.generate!

      abort red("#{message}\n#{errors.join("\n")}") unless errors.empty?

      puts green 'Schema is compatible'
    end

    desc 'Check if the schema file exists'
    task unchanged: 'graphiti:schema:file_exists' do
      file = Graphiti.config.schema_path
      before = Digest::MD5.hexdigest(file.read)
      Graphiti::Schema.generate!
      after = Digest::MD5.hexdigest(file.read)

      if before != after
        abort red(<<~MSG)
          Schema file is outdated: #{file}

          Run `bundle exec rake graphiti:schema:generate` and commit the file to the git repository.
        MSG
      end

      puts green 'Schema file is up to date'
    end

    desc 'Generate or update the schema file'
    task generate: 'graphiti:schema:compatible' do
      puts green <<~MSG
        Schema file has been updated: #{pretty_schema_path}
        Do not forget to commit the file to the git repository.
      MSG
    end

    desc 'Overwrite the schema file'
    task overwrite: 'graphiti:schema:setup' do
      memo = ENV['FORCE_SCHEMA']
      ENV['FORCE_SCHEMA'] = 'true'

      Graphiti::Schema.generate!

      ENV['FORCE_SCHEMA'] = memo
      puts green <<~MSG
        Schema file has been overwritten: #{pretty_schema_path}
        Do not forget to commit the file to the git repository.
      MSG
    end

  end

end
