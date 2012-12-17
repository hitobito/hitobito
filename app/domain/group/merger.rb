class Group::Merger < Struct.new(:group1, :group2, :new_group_name)

  attr_reader :new_group

  def initialize(*args)
    super
    create_new_group
    update_events
    copy_roles
    move_children
    delete_old_groups
  end

  def create_new_group
    new_group = group1.class.new
    new_group.name = new_group_name
    new_group.parent_id = group1.parent_id
    new_group.save!
    new_group.reload
    @new_group = new_group
  end

  def update_events
    events = group1.events.push(group2.events)
    events.each do |event|
      event.groups = event.groups.push(new_group)
      event.save!
    end
  end

  def move_children
    children = group1.children.push(group2.children)
    children.each do |group|
      group.parent_id = new_group.id
      group.save!
    end

  end

  def copy_roles
    roles = group1.roles.push(group2.roles)
    roles.each do |role| 
      new_role = role.dup
      new_role.group_id = new_group.id
      new_role.save!
    end

  end

  def delete_old_groups
    group1.destroy!
    group2.destroy!
  end

end
