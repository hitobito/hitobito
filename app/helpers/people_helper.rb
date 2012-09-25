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

  def role_group_info(role)
    group_link = link_to(role.group, role.group)
    "#{role.class.model_name.human} in #{group_link}".html_safe
  end
end
