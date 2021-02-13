# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_kinds
#
#  id          :integer          not null, primary key
#  created_at  :datetime
#  updated_at  :datetime
#  deleted_at  :datetime
#  minimum_age :integer
#

class Event::Kind < ActiveRecord::Base

  include Paranoia::Globalized
  translates :label, :short_name, :general_information, :application_conditions

  ### ASSOCIATIONS

  has_many :events

  has_many :event_kind_qualification_kinds, class_name: "Event::KindQualificationKind",
                                            foreign_key: "event_kind_id"


  ### VALIDATIONS

  validates_by_schema
  # explicitly define validations for translated attributes
  validates :label, presence: true
  validates :label, :short_name, length: { allow_nil: true, maximum: 255 }
  validates :minimum_age, numericality: { greater_than_or_equal_to: 0, allow_blank: true }


  accepts_nested_attributes_for :event_kind_qualification_kinds, allow_destroy: true


  before_validation :set_self_in_nested

  ### INSTANCE METHODS

  def to_s(_format = :default)
    if short_name.present?
      "#{short_name} (#{label})"
    else
      label
    end
  end

  # is this event type qualifying
  def qualifying?
    event_kind_qualification_kinds.where("category IN (?)", %w(qualification prolongation)).exists?
  end

  def qualification_kinds(category, role)
    QualificationKind.
      includes(:translations).
      joins(:event_kind_qualification_kinds).
      where(event_kind_qualification_kinds: { event_kind_id: id,
                                              category: category,
                                              role: role })
  end

  def grouped_qualification_kind_ids(category, role)
    event_kind_qualification_kinds.grouped_qualification_kind_ids(category, role)
  end

  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if events.exists?
      delete
    else
      really_destroy!
    end
  end

  private

  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    event_kind_qualification_kinds.each do |e|
      unless e.frozen?
        e.event_kind = self
      end
    end
  end

end
