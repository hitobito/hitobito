# encoding: utf-8
# == Schema Information
#
# Table name: event_kinds
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#  minimum_age :integer
#


#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class Event::Kind < ActiveRecord::Base

  acts_as_paranoid
  extend Paranoia::RegularScope

  before_destroy :remember_translated_label
  translates :label, :short_name, fallbacks_for_empty_translations: true
  Translation.schema_validations_config.auto_create = false


  ### ASSOCIATIONS

  has_many :events

  # The qualifications to gain for this event kind
  has_and_belongs_to_many :qualification_kinds, join_table: 'event_kinds_qualification_kinds',
                                                foreign_key: :event_kind_id
  # The qualifications required to visit this event kind
  has_and_belongs_to_many :preconditions, join_table: 'event_kinds_preconditions',
                                          class_name: 'QualificationKind',
                                          foreign_key: :event_kind_id
  # The qualifications that are prolonged when visiting this event kind
  has_and_belongs_to_many :prolongations, join_table: 'event_kinds_prolongations',
                                          class_name: 'QualificationKind',
                                          foreign_key: :event_kind_id


  ### VALIDATIONS

  # explicitly define validations for translated attributes
  validates :label, presence: true
  validates :label, :short_name, length: { allow_nil: true, maximum: 255 }


  ### CLASS METHODS

  class << self
    def list
      with_translations.order(:deleted_at, 'event_kind_translations.label').uniq
    end
  end


  ### INSTANCE METHODS

  def to_s(_format = :default)
    "#{short_name} (#{label})"
  end

  # is this event type qualifying
  def qualifying?
    qualification_kinds.exists? || prolongations.exists?
  end

  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if events.exists?
      super
    else
      destroy!
    end
  end

  private

  def remember_translated_label
    to_s # fetches the required translations and keeps them around
  end

end
