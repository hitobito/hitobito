require 'ostruct'
class GroupExhibit < BaseExhibit
  def_delegators :context, :new_group_path

  def self.applicable_to?(object)
    return false if object.class.name == 'ActiveRecord::Relation'
    object.class.name == 'Group' || object.class.base_class.name == 'Group'
  end

  def possible_children
    self.class.possible_children.collect(&:model_name).map do |name|
      link = new_group_path(group: { parent_id: self.id, type: name})
      OpenStruct.new(target: link, name: name.human)
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
