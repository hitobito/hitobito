class RelationMigrator
  attr_reader :new_relations, :role_type, :role_type_name

  def initialize(role_type)
    @role_type = role_type
    @role_type_name = role_type.to_s.demodulize
  end

  def perform
    current_relations.each do |relation|
      specific_role_types(relation).each do |specific_role_type|
        relation.related_role_types.create(role_type: specific_role_type)
      end
      relation.related_role_types.where(role_type: role_type).destroy_all
    end
  end

  def current_relations
    @current_relations ||= relation_class
      .where(related_role_types: { role_type: role_type})
      .joins(:related_role_types)
  end

  private

  def specific_role_types(relation)
    group = group_for(relation)
    role_types_for(group.class.child_types)
  end

  def role_types_for(groups)
    groups.map do |child_group_class|
      child_group_class.const_defined?(:"#{role_type_name}") ? "#{child_group_class}::#{role_type_name}" : nil
    end.compact
  end

end

class PeopleFilterMigrator < RelationMigrator
  def relation_class
    PeopleFilter
  end

  def group_for(relation)
    relation.group
  end
end

class SubscriptionMigrator < RelationMigrator
  def relation_class
    Subscription
  end

  def group_for(relation)
    relation.subscriber
  end

  def current_relations
    super.where(subscriber_type: 'Group')
  end


end

