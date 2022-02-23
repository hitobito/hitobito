# == Schema Information
#
# Table name: table_displays
#
#  id        :integer          not null, primary key
#  selected  :text(16777215)
#  type      :string(255)      not null
#  person_id :integer          not null
#
# Indexes
#
#  index_table_displays_on_person_id_and_type  (person_id,type) UNIQUE
#

class TableDisplay::People < TableDisplay
  def available
    Person.column_names + calculated - excluded
  end

  def calculated
    %w(login_status)
  end

  def excluded
    %w(first_name last_name nickname zip_code town address) +
      Person::INTERNAL_ATTRS.collect(&:to_s) +
      %w(picture primary_group_id)
  end

end
