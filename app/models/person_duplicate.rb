# == Schema Information
#
# Table name: person_duplicates
#
#  id                   :integer          not null, primary key
#  person_1_id          :integer          not null
#  person_2_id          :integer          not null
#  ignore               :boolean          default(FALSE), not null
#

class PersonDuplicate < ActiveRecord::Base

  belongs_to :person_1, class_name: 'Person'
  belongs_to :person_2, class_name: 'Person'

  before_save :assign_persons_sorted_by_id
  # Sorting by id to only allow a single PersonDuplicate entry per Person combination
  def assign_persons_sorted_by_id
    self.person_1, self.person_2 = [self.person_1, self.person_2].sort_by(&:id)
  end

end
