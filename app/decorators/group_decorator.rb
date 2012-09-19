class GroupDecorator < BaseDecorator
  decorates :group

  def possible_children_links
    model.class.possible_children.map do |type|
      link = h.new_group_path(group: { parent_id: self.id, type: type.sti_name})
      [type.model_name.human, link]
    end
  end

  def possible_role_links
    model.class.roles.map do |type|
      link = h.new_group_role_path(self, role: { type: type.sti_name})
      [type.model_name.human, link]
    end
  end
  
  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }
  end

  def modifiable_attributes(*attributes)
    attributes = used_attributes(*attributes)
    attributes -= model.class.superior_attributes unless h.can?(:modify_superior, self)
    attributes
  end

end
