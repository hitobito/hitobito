module PeopleHelper

  def format_gender(person)
    gender_label(person.gender)
  end
  
  def gender_label(gender)
    t("activerecord.attributes.person.genders.#{gender.presence || 'default'}")
  end

  def send_login_button
    if can?(:send_password_instructions, entry) 
      action_button 'Login schicken', send_password_instructions_group_person_path(parent, entry), nil,
        remote: true, method: :post
    end
  end

end
