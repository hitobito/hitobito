module PeopleHelper
  
  # render a list of all roles
  # if a group is given, only render the roles of this group
  def render_roles(person, group = nil)
    roles = person.roles
    roles.select!{|r| r.group_id == group.id } if group
    safe_join(roles) do |role|
      content_tag(:p) do
        html = [role.to_s]
        html << muted(role.group.to_s) if group.nil?
        safe_join(html, ' ')
      end
    end
  end
  
  def format_gender(person)
    gender_label(person.gender)
  end
  
  def gender_label(gender)
    t("activerecord.attributes.person.genders.#{gender.presence || 'default'}")
  end

  def person_remove_link(person)
    path = group_role_path(person.group.id, person.id)
    link_to ti(:"link.delete"), path, data: { confirm: ti(:confirm_delete), method: :delete } 
  end
end
