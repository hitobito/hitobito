# encoding: utf-8
class PersonDecorator < BaseDecorator
  decorates :person

  def self.gender_collection
    [OpenStruct.new(value: 'unbekannt', key: ''), 
     OpenStruct.new(value: 'männlich', key: 'm'), 
     OpenStruct.new(value: 'weiblich', key: 'w')]
  end

  def as_typeahead
    {id: id, name: full_label}
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
