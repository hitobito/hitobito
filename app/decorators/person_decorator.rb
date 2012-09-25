# encoding: utf-8
class PersonDecorator < BaseDecorator
  decorates :person

  include ContactableDecorator

  def as_typeahead
    {id: id, name: full_label}
  end

  def full_name
    model.to_s.split('/').first
  end
  
  def full_label
    label = to_s
    label << ", #{town}" if town?
    if company?
      name = "#{first_name} #{last_name}".strip
      label << " (#{name})" if name.present?
    else
      label << " (#{birthday.year})" if birthday
    end
    label
  end

end
