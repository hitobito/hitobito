# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class PassGrant < ActiveRecord::Base
  include RelatedRoleType::Assigners

  belongs_to :pass_definition
  belongs_to :grantor, polymorphic: true # Group (Event in future phase)
  has_many :related_role_types, as: :relation, dependent: :destroy

  # Future: include RelatedQualificationType::Assigners (WP 13)
  # Future: has_many :related_qualification_types, as: :relation, dependent: :destroy

  scope :group_grants, -> { where(grantor_type: "Group") }

  # Extracted as method for Future Phase extensibility (WP 13: qualification-based passes).
  # Will become: has_role_types_or_qualification_types
  validate :has_eligibility_criteria
  validates :grantor_id, uniqueness: {scope: [:pass_definition_id, :grantor_type]}

  after_save :populate_passes

  private

  def populate_passes
    PassPopulateJob.new(pass_definition_id).enqueue!
  end

  def has_eligibility_criteria
    if related_role_types.reject(&:marked_for_destruction?).empty?
      errors.add(:related_role_types, :blank)
    end
  end
end
