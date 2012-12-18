module PopulationHelper

  BADGE_INVALID = '<span class="text-error">Angabe fehlt</span>'.html_safe

  def person_birthday_with_check(person)
    if person.birthday.blank?
      BADGE_INVALID
    else
      l(person.birthday)
    end
  end

  def person_gender_with_check(person)
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
