class Migrator < Struct.new(:role_type)

  def perform
    check
    update_roles

    subscription.perform
    filter.perform
  end

  def subscription
    @abo_migrator ||= SubscriptionMigrator.new(role_type)
  end

  def filter
    @filter_migrator ||= PeopleFilterMigrator.new(role_type)
  end

  private

  def check
    group_types_roles_map.values.each(&:constantize)
  end

  def update_roles
    group_types_roles_map.each do |group_type, new_role_type|
      role_type.joins(:group).update_all("roles.type = '#{new_role_type}'",
                                         "groups.type = '#{group_type}'")
    end
  end

  def group_types_roles_map
    @group_types_roles_map ||= role_type.joins(:group).pluck(:'groups.type').uniq.each_with_object({}) do |group_type, hash|
      hash[group_type] = "#{group_type}::#{role_type.to_s.demodulize}"
    end
  end
end
