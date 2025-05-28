# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :hitobito do
  desc "Print all groups, roles and permissions"
  task :roles, [:with_classes] => [:environment] do |_t, args| # rubocop:disable Rails/RakeEnvironment
    args.with_defaults({with_classes: false})
    with_classes = args[:with_classes].to_s == "true"

    group_tree = Group.subclasses.index_by(&:label).map { |label, klass| [label, klass.children.map(&:label)] }.to_h

    Role::TypeList.new(Group.root_types.first).each do |layer, groups|
      super_layers = group_tree.select { |_key, list| list.include?(layer) }.keys
      super_layer_tag = " < #{super_layers.join(", ")}" if super_layers.any?

      puts "    * #{layer}#{super_layer_tag}"
      groups.each do |group, roles|
        puts "      * #{group}"
        roles.each do |r|
          twofa_tag = "2FA " if r.two_factor_authentication_enforced
          role_class_info = "  --  (#{r})" if with_classes

          puts "        * #{r.label}: #{twofa_tag}#{r.permissions.inspect}#{role_class_info}"
        end
      end
    end
  end

  desc "Drop all tables and clear schema migrations"
  task :yippi_jay_jey_schweinebacke, [:wagon] => :environment do |_t, args| # rubocop:disable Rails/RakeEnvironment
    # Get parameter
    args.with_defaults({wagon: "generic"})
    wagon = args[:wagon].to_s == "true"

    # Drop all tables except rails internals
    connection = ActiveRecord::Base.connection
    rails_internal_tables = ["schema_migrations", "ar_internal_metadata"]
    tables_to_delete = connection.tables - rails_internal_tables
    tables_to_delete.each do |table|
      connection.execute("DROP TABLE IF EXISTS #{table} CASCADE")
    end

    # Truncate rails internals
    rails_internal_tables.each do | table|
      connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE")
    end

    # Run Migrations
    Rake::Task["db:migrate"].invoke
    # Rake::Task["wagon:migrate"].invoke
  end

  namespace :roles do
    task update_readme: :environment do
      stdout, _stderr, status = Open3.capture3("rake app:hitobito:roles")
      raise "failed to generate role docs with `rake app:hitobito:roles`" unless status.success?

      roles = "#{stdout}\n(Output of rake app:hitobito:roles)"
      start_tag = "<!-- roles:start -->"
      end_tag = "<!-- roles:end -->"
      pattern = /#{start_tag}(.*)#{end_tag}/m
      readme_contents = File.read("README.md").strip

      updated_contents = if pattern.match?(readme_contents)
        readme_contents.gsub(pattern, "#{start_tag}\n#{roles}\n#{end_tag}")
      else
        "#{readme_contents}\n\n#{start_tag}\n#{roles}\n#{end_tag}\n"
      end

      File.write("README.md", updated_contents)
    end
  end

  desc "Print all abilities"
  task abilities: :environment do
    puts ["Permission".ljust(18), "\t",
      "Class".ljust(24), "\t",
      "Action".ljust(25), "\t",
      "Constraint"].join
    puts "=" * 100
    all = Role::Permissions + [AbilityDsl::Recorder::General::PERMISSION]
    Ability.store.configs_for_permissions(all) do |c|
      puts "#{c.permission.to_s.ljust(18)}\t" \
           "#{c.subject_class.to_s.ljust(24)}\t" \
           "#{c.action.to_s.ljust(25)}\t" \
           "#{c.constraint}"
    end
  end

  desc "Check existence of needed configurations and settings"
  task check_config: [
    "hitobito:checks:oauth",
    "hitobito:checks:self_registration_rules"
  ]

  namespace :checks do
    task oauth: :environment do
      signing_key = Settings.oidc.signing_key.join.presence

      if signing_key.nil?
        puts <<~MESSAGE
          ❌ OAuth not correctly configured

            JWT Signing Key missing.
            This key is needed for OAuth to work.
            See doc/development/08_oauth.md for details

        MESSAGE
      else
        puts "✅ OAuth configured"
      end
    end

    task self_registration_rules: :environment do
      class SelfRegistrationRoleTypeChecker # rubocop:disable Lint/ConstantDefinitionInBlock
        attr_reader :errors

        def initialize(allowed_permissions = [])
          @allowed_permissions = allowed_permissions
          @errors = []
        end

        def check
          offending_self_registrations.each do |group|
            @errors << "Group ##{group.id} '#{group.name}' uses self registration with " \
                       "#{group.self_registration_role_type} " \
                       "(#{group.self_registration_role_type.constantize.permissions.to_sentence})"
          end

          @errors.none?
        end

        private

        def allowed_role_types_by_group_type
          Group.all_types.index_with do |group_type|
            group_type.role_types.reject do |role_type|
              role_type.restricted? || (role_type.permissions - @allowed_permissions).any?
            end
          end
        end

        def offending_self_registrations
          allowed_role_types_by_group_type.flat_map do |group_type, allowed_role_types|
            Group.where(type: group_type.sti_name)
              .where.not(self_registration_role_type: allowed_role_types.map(&:sti_name) + [nil, ""])
          end.compact
        end
      end

      checker = SelfRegistrationRoleTypeChecker.new

      if checker.check
        puts "✅ SelfRegistrationRoleTypes configured correctly"
      else
        puts "❌ SelfRegistrationRoleTypes are giving to much rights"
        puts checker.errors.join("\n")
      end
    end
  end

  desc "Parse Structure and output classes and translations"
  task :parse_structure, [:filename] => [:environment] do |_t, args|
    require_relative "../../app/domain/structure_parser"
    args.with_defaults({
      filename: "./structure.txt"
    })

    file = Pathname.new(args[:filename]).expand_path
    dry_run = ENV["DRY_RUN"] == "true"

    puts "-------- Parsing #{file}"
    parser = StructureParser.new(
      file.read,
      common_indent: 4,
      shiftwidth: 2,
      list_marker: "*",
      allowed_permissions: Role::Permissions + [AbilityDsl::Recorder::General::PERMISSION]
    )
    puts parser.inspect if dry_run
    parser.parse
    if parser.valid?
      puts "Structure and Permissions seem valid."
    else
      puts(*parser.errors)
      puts
      raise "Inputfile seems invalid."
    end

    puts "-------- Groups and Roles as classes ------"
    group_path = file.dirname.join("app", "models", "group")
    puts "writing classes to #{group_path}"
    parser.output_groups.each do |fn, content|
      if dry_run
        puts fn, content
      else
        group_path.join(fn).write(content)
        print "."
      end
    end
    puts ""

    puts "-------- Translations for those -----------"
    locale_path = file.dirname.join("config", "locales").children.first
    if dry_run
      puts locale_path
      puts parser.output_translations
    else
      locale_path.write(parser.output_translations)
      puts "written to #{locale_path}"
    end

    puts "-------- Done."
    unless dry_run
      puts <<~MSG

        Next steps:
        -----------

        Update the root-groups in your wagon, so that

          rake app:hitobito:roles:update_readme

        works as intended. Take a lookt at

          #{file.dirname.glob("app/models/*/group.rb").first}

        Have fun.
      MSG
    end
  end
end
