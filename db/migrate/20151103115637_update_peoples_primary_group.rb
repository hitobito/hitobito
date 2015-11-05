class UpdatePeoplesPrimaryGroup < ActiveRecord::Migration
  def up
    # people with no primary group and only one active role
    people = Person.joins(:roles).where(primary_group_id: nil).group('people.id').having('count(distinct roles.group_id) = 1')
    people.find_each do |p|
      group_id = p.roles.first.group_id
      p.update_column(:primary_group_id, group_id)
    end
  end
end
