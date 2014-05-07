# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.



# == Schema Information
#
# Table name: qualification_kinds
#
#  id             :integer          not null, primary key
#  validity       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#  reactivateable :integer
#
class QualificationKind < ActiveRecord::Base

  acts_as_paranoid
  extend Paranoia::RegularScope


  before_destroy :remember_translated_label
  translates :label, :description, fallbacks_for_empty_translations: true
  Translation.schema_validations_config.auto_create = false


  ### ASSOCIATIONS

  has_many :qualifications


  has_and_belongs_to_many :event_kinds, join_table: 'event_kinds_qualification_kinds',
                                        class_name: 'Event::Kind',
                                        association_foreign_key: :event_kind_id
  has_and_belongs_to_many :preconditions, join_table: 'event_kinds_preconditions',
                                          class_name: 'Event::Kind',
                                          association_foreign_key: :event_kind_id
  has_and_belongs_to_many :prolongations, join_table: 'event_kinds_prolongations',
                                          class_name: 'Event::Kind',
                                          association_foreign_key: :event_kind_id

  ### VALIDATES

  validates :label, presence: true, length: { maximum: 255, allow_nil: true }
  validates :description, length: { maximum: 1023, allow_nil: true }
  validates :reactivateable, numericality: { greater_than_or_equal_to: 1, allow_nil: true }

  validate :assert_validity_when_reactivateable


  ### CLASS METHODS

  class << self
    def list
      with_translations.order(:deleted_at, 'qualification_kind_translations.label').uniq
    end
  end

  ### INSTANCE METHODS

  def to_s(_format = :default)
    label
  end

  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if qualifications.exists?
      super
    else
      destroy!
    end
  end


  private

  def assert_validity_when_reactivateable
    if reactivateable.present? && (validity.to_i <= 0)
      errors.add(:validity, :not_a_positive_number)
    end
  end

  def remember_translated_label
    to_s # fetches the required translations and keeps them around
  end

end
