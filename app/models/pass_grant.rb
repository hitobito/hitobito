# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# == Schema Information
#
# Table name: pass_grants
#
#  id                 :bigint           not null, primary key
#  grantor_type       :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  grantor_id         :bigint           not null
#  pass_definition_id :bigint           not null
#
# Indexes
#
#  idx_pass_grants_unique  (pass_definition_id,grantor_type,grantor_id) UNIQUE
#
class PassGrant < ActiveRecord::Base
  include RelatedRoleType::Assigners

  ### ASSOCIATIONS

  belongs_to :pass_definition
  belongs_to :grantor, polymorphic: true # Group (Event in future phase)
  has_many :related_role_types, as: :relation, dependent: :destroy

  # Future: include RelatedQualificationType::Assigners (qualification-based passes).
  # Future: has_many :related_qualification_types, as: :relation, dependent: :destroy

  ### VALIDATIONS

  validates_by_schema

  # Extracted as method for Future Phase extensibility (qualification-based passes).
  # Will become: has_role_types_or_qualification_types
  validate :has_eligibility_criteria
  validates :grantor_id, uniqueness: {scope: [:pass_definition_id, :grantor_type]}
  validates :grantor_type, presence: true

  ### CALLBACKS

  after_save :populate_passes

  ### SCOPES

  scope :group_grants, -> { where(grantor_type: "Group") }

  ### INSTANCE METHODS

  def grouped_role_types
    result = {}
    role_classes = related_role_types.map(&:role_class)
    Role::TypeList.new(grantor.class).each do |layer, groups|
      groups_result = {}
      groups.each do |group, role_types|
        role_types_result = role_types.select { |rt| role_classes.include?(rt) }
        groups_result[group] = role_types_result if role_types_result.present?
      end
      result[layer] = groups_result if groups_result.present?
    end
    result
  end

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
