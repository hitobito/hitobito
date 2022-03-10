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
  def table_model_class
    Person
  end
end
