# == Schema Information
#
# Table name: table_displays
#
#  id        :integer          not null, primary key
#  type      :string(255)      not null
#  person_id :integer          not null
#  selected  :text(65535)
#

class TableDisplay::People < TableDisplay
  def available
    Person.column_names - excluded
  end

  def excluded
    %w(first_name last_name nickname zip_code town address) +
      Person::INTERNAL_ATTRS.collect(&:to_s) +
      %w(picture primary_group_id)
  end

end
