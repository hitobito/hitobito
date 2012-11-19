module PopulationHelper

  def person_edit_link(person)
    link_to(icon(:edit), 
            edit_group_person_path(person, group_id: @group.id, 
                                   return_url: population_group_path(@group.id)),
            title: 'Bearbeiten', alt: 'Bearbeiten')
  end

  def person_birthday(person)
    if person.birthday.blank?
      badge_invalid
    else
      l(person.birthday)
    end
  end

  def person_gender(person)
    if person.gender.blank?
      badge_invalid
    else
      gender_label(person.gender)
    end
  end

  def badge_invalid
    '<span class="badge badge-important"><i class="icon-exclamation-sign icon-white"></i></span>'.html_safe
  end

  def tab_population_label
    label = 'Bestand'
    label << " #{tab_attention_badge}" if check_approveable?
    label.html_safe
  end

  def tab_attention_badge
    '<span style="color: red;">!</span>'
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
