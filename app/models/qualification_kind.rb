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
#  created_at     :datetime
#  updated_at     :datetime
#  deleted_at     :datetime
#  reactivateable :integer
#
class QualificationKind < ActiveRecord::Base

  include Paranoia::Globalized
  translates :label, :description

  ### ASSOCIATIONS

  has_many :qualifications

  has_many :event_kind_qualification_kinds, class_name: 'Event::KindQualificationKind'
  has_many :event_kinds, through: :event_kind_qualification_kinds


  ### VALIDATES

  validates :label, presence: true, length: { maximum: 255, allow_nil: true }
  validates :description, length: { maximum: 1023, allow_nil: true }
  validates :reactivateable, numericality: { greater_than_or_equal_to: 1, allow_nil: true }

  validate :assert_validity_when_reactivateable


  ### INSTANCE METHODS

  def to_s(_format = :default)
    label
  end

  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if qualifications.exists?
      touch_paranoia_column(true)
    else
      really_destroy!
    end
  end

  private

  def assert_validity_when_reactivateable
    if reactivateable.present? && (validity.to_i <= 0)
      errors.add(:validity, :not_a_positive_number)
    end
  end

end
