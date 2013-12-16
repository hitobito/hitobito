class Person::ListFilter

  attr_reader :group, :user, :kind, :filter, :multiple_groups

  def initialize(group, user, kind, role_type_ids)
    @group = group
    @user = user
    @kind = kind.to_s
    @filter = PeopleFilter.new(role_type_ids: role_type_ids)
  end

  def filter_entries
    if filter.role_types.present?
      list_entries(kind).where(roles: { type: filter.role_types })
    else
      list_entries.members
    end
  end

  def list_entries(scope_kind = nil)
    list_scope(scope_kind).
          preload_groups.
          uniq.
          order_by_role.
          order_by_name
  end

  def list_scope(scope_kind = nil)
    case scope_kind
    when 'deep'
      @multiple_groups = true
      accessibles.in_or_below(group)
    when 'layer'
      @multiple_groups = true
      accessibles.in_layer(group)
    else
      accessibles(group)
    end
  end

  def accessibles(group = nil)
    ability = PersonAccessibles.new(user, group)
    Person.accessible_by(ability)
  end

end