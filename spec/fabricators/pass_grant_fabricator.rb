Fabricator(:pass_grant) do
  pass_definition
  grantor { Group.root }
  after_build do |grant|
    if grant.related_role_types.empty?
      grant.role_types = [Group::TopGroup::Leader.sti_name]
    end
  end
end
