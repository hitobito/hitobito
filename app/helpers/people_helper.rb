module PeopleHelper
  
  def render_roles(person)
    safe_join(person.roles) do |role|
      content_tag(:p) do
        html = [role.to_s]
        html << muted(role.group.to_s) if role.group_id != @group.id
        safe_join(html, ' ')
      end
    end
  end
end