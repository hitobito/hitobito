# encoding: utf-8
class PersonDecorator < BaseDecorator
  decorates :person

  def self.gender_keys_with_labels
    @keys_with_labels ||= { m: 'männlich', w: 'weiblich', u: 'unbekannt' }
  end

  def radio_for_gender(f,key)
    f.label "gender_#{key}", class: 'inline checkbox' do
      f.radio_button(:gender, key) + PersonDecorator.gender_keys_with_labels[key]
    end
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
