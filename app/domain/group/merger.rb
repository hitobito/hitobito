class Group::Merger < Struct.new(:group1, :group2, :new_group_name)

  attr_reader :new_group

  def merge!

    raise('Cant merge these Groups') unless group2_valid?

    ::Group.transaction do 
      create_new_group
      update_events
      copy_roles
      move_children(group1)
      move_children(group2)
      delete_old_groups
    end
  end

  def group2_valid?
    (group1.class == group2.class && group1.parent_id == group2.parent_id)
  end

  private
  def create_new_group
    new_group = group1.class.new
    new_group.name = new_group_name
    new_group.parent_id = group1.parent_id
    new_group.save!
    new_group.reload
    @new_group = new_group
  end

  def update_events
    events = group1.events + group2.events
    events.each do |event|
      event.groups << new_group
      event.save!
    end
  end

  def move_children(group)
    children = group1.children + group2.children
    children.each do |child|
      child.parent_id = new_group.id
      child.save!
    end
    group.children.update_all(parent_id: new_group.id)
  end

  def copy_roles
    roles = group1.roles + group2.roles
    roles.each do |role| 
      new_role = role.dup
      new_role.group_id = new_group.id
      new_role.save!
    end

  end

  def delete_old_groups
    group1.destroy
    group2.destroy
  end

end
