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
  translates :label, :short_name

  ### ASSOCIATIONS

  has_many :events

  has_many :event_kind_qualification_kinds, class_name: 'Event::KindQualificationKind',
                                            foreign_key: 'event_kind_id'


  ### VALIDATIONS

  # explicitly define validations for translated attributes
  validates :label, presence: true
  validates :label, :short_name, length: { allow_nil: true, maximum: 255 }


  accepts_nested_attributes_for :event_kind_qualification_kinds, allow_destroy: true


  before_validation :set_self_in_nested

  ### INSTANCE METHODS

  def to_s(_format = :default)
    "#{short_name} (#{label})"
  end

  # is this event type qualifying
  def qualifying?
    event_kind_qualification_kinds.where('category IN (?)', %w(qualification prolongation)).exists?
  end

  def qualification_kinds(category, role)
    QualificationKind.includes(:translations).
                      joins(:event_kind_qualification_kinds).
                      where(event_kind_qualification_kinds: { event_kind_id: id,
                                                              category: category,
                                                              role: role })
  end

  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if events.exists?
      touch_paranoia_column(true)
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
