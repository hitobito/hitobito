module PopulationHelper

  BADGE_INVALID = '<span class="badge badge-important"><i class="icon-exclamation-sign icon-white"></i></span>'.html_safe

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
  
  def tab_population_label(group)
    label = 'Bestand'
    label << " <span style=\"color: red;\">!</span>" if check_approveable?(group)
    label.html_safe
  end

  def check_approveable?(group = @group)
    group.population_approveable? && can?(:create_member_counts, group)
  end

end
