# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
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
  belongs_to :person_1, class_name: "Person"
  belongs_to :person_2, class_name: "Person"

  scope :list, -> { where(ignore: false).order(:created_at) }

  validates :person_1_id, uniqueness: {scope: [:person_2_id]}

  validate :valid_role_operations, if: -> { validation_context == :merge }

  before_save :assign_persons_sorted_by_id
  # Sorting by id to only allow a single PersonDuplicate entry per Person combination
  def assign_persons_sorted_by_id
    self.person_1, self.person_2 = [person_1, person_2].sort_by(&:id)
  end

  def persons_valid?
    person_1.valid? && person_2.valid?
  end

  # This validation checks if all roles are valid when merging, to prevent exceptions when merging.
  # rubocop:todo Layout/LineLength
  # We check both cases for target and source, no matter which one was selected as the prefered option.
  # rubocop:enable Layout/LineLength
  def valid_role_operations
    validate_roles(person_1, person_2_id)
    validate_roles(person_2, person_1_id)
  end

  private

  def validate_roles(person, new_person_id)
    person.roles.with_inactive.each do |role|
      role.person_id = new_person_id
      unless role.valid?
        errors.add(
          :base,
          I18n.t("activerecord.errors.models.person_duplicates.invalid_role",
            role: role.to_s,
            person: person,
            message: role.errors.full_messages.join(", "))
        )
      end
    end
  end
end
