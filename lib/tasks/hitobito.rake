# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :hitobito do
  desc "Print all groups, roles and permissions"
  task :roles => :environment do
    Role::TypeList.new(Group.root_types.first).each do |layer, groups|
      puts '   * ' + layer
      groups.each do |group, roles|
        puts '      * ' + group
        roles.each do |r|
          puts "         * #{r.model_name.human}: #{r.permissions.inspect}"
        end
      end
    end
  end

  desc "Print all abilities"
  task :abilities => :environment do
    puts ['Permission'.ljust(18), "\t",
          'Class'.ljust(24), "\t",
          'Action'.ljust(25), "\t",
          'Constraint'].join()
    puts '=' * 100
    all = Role::Permissions + [AbilityDsl::Recorder::General::PERMISSION]
    Ability.store.configs_for_permissions(all) do |c|
      puts "#{c.permission.to_s.ljust(18)}\t" \
           "#{c.subject_class.to_s.ljust(24)}\t" \
           "#{c.action.to_s.ljust(25)}\t" \
           "#{c.constraint}"
    end
  end
end
