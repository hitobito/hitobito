module RelatedRoleType::Assigners
  def role_types
    @role_types ||= related_role_types.collect(&:role_type)
  end
  
  def role_types=(types)
    @role_types = Array(types.presence)
    self.related_role_types = @role_types.collect {|t| RelatedRoleType.new(role_type: t) }
  end
end