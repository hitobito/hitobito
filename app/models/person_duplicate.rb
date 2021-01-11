# == Schema Information
#
# Table name: person_duplicates
#
#  id          :bigint           not null, primary key
#  ignore      :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  person_1_id :integer          not null
#  person_2_id :integer          not null
#
# Indexes
#
#  index_person_duplicates_on_person_1_id_and_person_2_id  (person_1_id,person_2_id) UNIQUE
#

class PersonDuplicate < ActiveRecord::Base

  belongs_to :person_1, class_name: 'Person'
  belongs_to :person_2, class_name: 'Person'

  scope :list, -> { where(ignore: false).order(:created_at) }

  before_save :assign_persons_sorted_by_id
  # Sorting by id to only allow a single PersonDuplicate entry per Person combination
  def assign_persons_sorted_by_id
    self.person_1, self.person_2 = [self.person_1, self.person_2].sort_by(&:id)
  end

  def persons_valid?
    person_1.valid? && person_2.valid?
  end


end
