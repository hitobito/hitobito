
namespace :hitobito do
  desc "Print all groups, roles and permissions"
  task :permissions => :environment do
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
    puts ['Permission'.ljust(18), "\t", 'Class'.ljust(24), "\t", 'Action'.ljust(25), "\t", 'Constraint'].join()
    puts '=' * 100
    Ability.store.configs_for_permissions(Role::Permissions + [AbilityDsl::Recorder::General::Permission]) do |c|
      puts "#{c.permission.to_s.ljust(18)}\t#{c.subject_class.to_s.ljust(24)}\t#{c.action.to_s.ljust(25)}\t#{c.constraint}"
    end
  end
end
