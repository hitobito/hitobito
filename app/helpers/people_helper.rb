# encoding: UTF-8

module PeopleHelper

  def format_gender(person)
    gender_label(person.gender)
  end
  
  def gender_label(gender)
    t("activerecord.attributes.person.genders.#{gender.presence || 'default'}")
  end
  
  def can_export_people_details?
    if params[:kind].blank? 
      can?(:index_full_people, @group)
    else
      can?(:index_deep_full_people, @group)
    end
  end

  def dropdown_people_export(details = false)
    Dropdown::PeopleExport.new(self, current_user, params, details).to_s
  end

end
