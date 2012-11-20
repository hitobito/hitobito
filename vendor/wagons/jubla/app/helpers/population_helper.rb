module PopulationHelper

  BADGE_INVALID = '<span class="badge badge-important"><i class="icon-exclamation-sign icon-white"></i></span>'.html_safe

  def person_edit_link(person)
    link_to(icon(:edit), 
            edit_group_person_path(person, group_id: @group.id, 
                                   return_url: population_group_path(@group.id)),
            title: 'Bearbeiten', alt: 'Bearbeiten')
  end

  def person_birthday(person)
    if person.birthday.blank?
      BADGE_INVALID
    else
      l(person.birthday)
    end
  end

  def person_gender(person)
    if person.gender.blank?
      BADGE_INVALID
    else
      gender_label(person.gender)
    end
  end
  
  def tab_population_label
    label = 'Bestand'
    label << " <span style=\"color: red;\">!</span>" if check_approveable?
    label.html_safe
  end

  def check_approveable?
    @group.population_approveable? && can?(:create_member_counts, @group)
  end

  def people_data_complete?
    @people.each do |p|
      return false if p.birthday.blank?
      return false if p.gender.blank?
    end
    true
  end

end
