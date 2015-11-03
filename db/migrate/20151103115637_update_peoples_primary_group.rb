class UpdatePeoplesPrimaryGroup < ActiveRecord::Migration
  def up
    people = Person.joins(:roles).where(primary_group_id: nil).having('count(distinct roles.group_id) = 1')
    people.update_all('primary_group_id = roles.group_id')
    #people.find_each do |p|
      #group_id = p.roles.first.group_id
      #p.update_column(:primary_group_id, group.id)
    #end
  end
end
