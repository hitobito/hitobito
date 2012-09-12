class GroupExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Group'
  end

  def possible_types
    parent.class.possible_children.collect(&:model_name)
  end

  def attrs_for_remote
    url = context.fields_groups_path(group: { parent_id: parent.id })
    url = URI.unescape(url)
    { data: { remote: true, replace: true, url: url }  } 
  end

end
