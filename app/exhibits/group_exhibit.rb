require 'ostruct'
class GroupExhibit < BaseExhibit
  #def_delegators :context, :new_group_path

  def self.applicable_to?(object)
    klass = object.class
    return false if klass.name == 'ActiveRecord::Relation'
    klass.respond_to?(:base_class) && klass.base_class.name == 'Group'
  end

  def possible_children_links
    self.class.possible_children.map do |type|
      link = context.new_group_path(group: { parent_id: self.id, type: type.sti_name})
      [type.model_name.human, link]
    end
  end

  def possible_role_links
    self.class.roles.map do |type|
      link = context.new_group_role_path(self, role: { type: type.sti_name})
      [type.model_name.human, link]
    end
  end
  
  def used_attributes(*attributes)
    attributes.select { |name| self.class.attr_used?(name) }
  end

  def modifiable_attributes(*attributes)
    attributes = used_attributes(*attributes)
    attributes -= self.class.superior_attributes unless can?(:modify_superior, self)
    attributes
  end
end
