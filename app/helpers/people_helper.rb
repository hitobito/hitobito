module PeopleHelper

  def format_gender(person)
    gender_label(person.gender)
  end
  
  def gender_label(gender)
    t("activerecord.attributes.person.genders.#{gender.presence || 'default'}")
  end

  def people_export_links
    links = []
    links << csv_links
  
    if @label_formats.present?
      main_link = current_user.last_label_format_id ?
                  export_label_format_path(current_user.last_label_format_id) :
                  '#'
      links << {link_to('Etiketten', main_link) => export_label_format_links(@label_formats) }
    end
      
    links
  end
  
  private

  def csv_links
    csv_path = params.merge({format: :csv})

    if can?(:index_full_people, @group)
      {link_to('CSV', '#') => [link_to('Adressliste', csv_path),
                               link_to('Alle Angaben', csv_path.merge(details: true))] }
    else
      link_to('CSV', csv_path)
    end
  end

  def export_label_format_links(label_formats)
    format_links = []
    if current_user.last_label_format_id?
      last_format = current_user.last_label_format
      format_links << export_label_format_link(last_format.id, last_format.to_s)
      format_links << nil
    end
    
    label_formats.each do |id, label|
      format_links << export_label_format_link(id, label)
    end
    format_links
  end
  
  def export_label_format_link(id, label)
    link_to(label, export_label_format_path(id))
  end
  
  def export_label_format_path(id)
    params.merge(format: :pdf, label_format_id: id)
  end

end
