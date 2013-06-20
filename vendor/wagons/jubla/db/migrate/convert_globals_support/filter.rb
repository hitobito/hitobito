class FilterMigrator < RelationMigrator
  def current_relations
    PeopleFilter
      .joins(:related_role_types)
      .where(related_role_types: { role_type: role_type})
  end

  def handle(filter)
    { id: filter.id, role_types: role_types_for(filter.group) }
  end

  def build(attrs)
    role_types = attrs.fetch(:role_types)
    if role_types.present?
      filter = PeopleFilter.find(attrs.fetch(:id))
      role_types.each { |role_type| filter.related_role_types.build(role_type: role_type) }
      filter
    end
  end
end

class AlumnusFilterMigrator < FilterMigrator
  def initialize
    super(Jubla::Role::Alumnus)
  end
end

class DispatchAddressFilterMigrator < FilterMigrator
  def initialize
    super(Jubla::Role::DispatchAddress)
  end
end
