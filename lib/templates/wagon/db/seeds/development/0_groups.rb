# encoding: utf-8

require Rails.root.join('db', 'seeds', 'support', 'group_seeder')

seeder = GroupSeeder.new

root = Group.roots.first
srand(42)

unless root.address.present?
  root.update_attributes(seeder.group_attributes)
  root.default_children.each do |child_class|
    child_class.first.update_attributes(seeder.group_attributes)
  end
end

# TODO: define more groups

Group.rebuild!
