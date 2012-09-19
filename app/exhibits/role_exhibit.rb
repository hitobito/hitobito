class RoleExhibit < BaseExhibit
  #def_delegators :context, :new_group_path

  def self.applicable_to?(object)
    klass = object.class
    return false if klass.name == 'ActiveRecord::Relation'
    klass.respond_to?(:base_class) && klass.base_class.name == 'Role'
  end

  def used_attributes(*attributes)
    attributes.select { |name| self.class.attr_used?(name) }
  end

end
