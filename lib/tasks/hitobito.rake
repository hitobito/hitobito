# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :hitobito do
  desc "Print all groups, roles and permissions"
  task roles: :environment do
    Role::TypeList.new(Group.root_types.first).each do |layer, groups|
      puts "    * #{layer}"
      groups.each do |group, roles|
        puts "      * #{group}"
        roles.each do |r|
          twofa_tag = "2FA " if r.two_factor_authentication_enforced
          puts "        * #{r.label}: #{twofa_tag}#{r.permissions.inspect}  --  (#{r})"
        end
      end
    end
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
  task :parse_structure, [:filename] do |_t, args| # rubocop:disable Rails/RakeEnvironment
    require_relative "../../app/domain/structure_parser"
    args.with_defaults({
      filename: "./structure.txt"
    })

    file = Pathname.new(args[:filename]).expand_path
    puts "-------- Parsing #{file}"

    parser = StructureParser.new(file.read, common_indent: 4, shiftwidth: 2, list_marker: "*")
    puts parser.inspect
    parser.parse

    puts "-------- Groups and Roles as classes ------"
    puts parser.output_groups
    puts "-------- Translations for those -----------"
    puts parser.output_translations
    puts "-------- Done."
  end
end
