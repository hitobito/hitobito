# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  admin            :boolean          default(FALSE), not null
#  multiple_choices :boolean          default(FALSE), not null
#  required         :boolean          default(FALSE), not null
#  event_id         :integer
#
# Indexes
#
#  index_event_questions_on_event_id  (event_id)
#

class Event::Question < ActiveRecord::Base

  include Globalized
  translates :question, :choices

  belongs_to :event
  has_many :answers, dependent: :destroy

  validates_by_schema

  # validate question presence for admin/non-admin questions separately
  # so we can have different error messages
  validates :question, presence: { message: :admin_blank }, if: :admin?
  validates :question, presence: { message: :application_blank }, unless: :admin?

  after_create :add_answer_to_participations

  scope :global, -> { where(event_id: nil) }
  scope :application, -> { where(admin: false) }
  scope :admin, -> { where(admin: true) }

  def required_attrs
    [
      # needed for the required attribute mark in forms
      # as the relevant validation is conditional
      :question
    ]
  end

  def choice_items
    choices.to_s.split(',').collect(&:strip)
  end

  def label
    # use safe navigation so not to break records missing the
    # question text created before validation was added
    question&.truncate(30)
  end

  def one_answer_available?
    choice_items.compact.one?
  end

  private

  def add_answer_to_participations
    return unless event

    event.participations.find_each do |p|
      p.answers << answers.new
    end
  end

end
