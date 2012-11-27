module PeopleHelper

  def format_gender(person)
    gender_label(person.gender)
  end
  
  def gender_label(gender)
    t("activerecord.attributes.person.genders.#{gender.presence || 'default'}")
  end

  def people_export_links
    links = []
    
    links << link_to('CSV', '#')
    
    label_formats = LabelFormat.all.to_a
    if label_formats.present?
      main_link = current_user.last_label_format_id ? 
                  export_label_format_path(current_user.last_label_format) : 
                  '#'
      links << {link_to('Etiketten', main_link) => export_label_format_links(label_formats) }
    end
      
    links
  end
  
  private
  
  def export_label_format_links(label_formats)
    format_links = []
    if current_user.last_label_format_id?
      format_links << export_label_format_link(current_user.last_label_format)
      format_links << nil
    end
    
    label_formats.each do |format| 
      format_links << export_label_format_link(format)
    end
    format_links
  end
  
  def export_label_format_link(format)
    link_to(format.to_s, export_label_format_path(format))
  end
  
  def export_label_format_path(format)
    params.merge(format: :pdf, label_format_id: format.id)
  end

end
