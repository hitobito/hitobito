class RoleDecorator < BaseDecorator
  decorates :role

  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }
  end
end
