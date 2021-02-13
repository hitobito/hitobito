# frozen_string_literal: true

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

class PersonDuplicate < ApplicationRecord
  belongs_to :person_1, class_name: "Person"
  belongs_to :person_2, class_name: "Person"

  scope :list, -> { where(ignore: false).order(:created_at) }

  validates :person_1_id, uniqueness: {scope: [:person_2_id]}

  before_save :assign_persons_sorted_by_id
  # Sorting by id to only allow a single PersonDuplicate entry per Person combination
  def assign_persons_sorted_by_id
    self.person_1, self.person_2 = [person_1, person_2].sort_by(&:id)
  end

  def persons_valid?
    person_1.valid? && person_2.valid?
  end
end
