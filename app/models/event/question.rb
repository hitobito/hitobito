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
#  choices          :string(255)
#  multiple_choices :boolean          default(FALSE), not null
#  question         :text(65535)
#  required         :boolean          default(FALSE), not null
#  event_id         :integer
#
# Indexes
#
#  index_event_questions_on_event_id  (event_id)
#

class Event::Question < ActiveRecord::Base
  include Globalized
  include I18nEnums

  # TODO: move choices
  translates :question, :choices

  belongs_to :event
  belongs_to :derived_from_question, class_name: "Event::Question", inverse_of: :derived_questions

  has_many :answers, dependent: :destroy
  has_many :derived_questions, class_name: "Event::Question", dependent: :destroy

  DISCLOSURE_VALUES  = %w[optional required hidden].freeze
  i18n_enum :disclosure, DISCLOSURE_VALUES #, scopes: true, queries: true

  validates_by_schema

  # validate question presence for admin/non-admin questions separately
  # so we can have different error messages
  validates :question, presence: {message: :admin_blank}, if: :admin?
  validates :question, presence: {message: :application_blank}, unless: :admin?
  validates :disclosure, presence: true, inclusion: {in: DISCLOSURE_VALUES}

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

  def derive
    self.dup.tap do |derived_question|
      derived_question.derived_from_question = self
    end
  end

  def label
    # use safe navigation so not to break records missing the
    # question text created before validation was added
    question&.truncate(30)
  end

  def serialize_answer(value)
    value
  end

  def validate_answer
    true
  end

  def add_to_existing_events
    return unless event_id.blank?

    existing_event_ids = Event.pluck(:id)
    derived_question_attributes = existing_event_ids.map do |event_id|
      standard_question.attributes.merge(id: nil, event_id: event_id)
    end

    Event::Question.insert_all(derived_question_attributes) if derived_questions.any?
  end

  private

  def add_answer_to_participations
    return unless event

    event.participations.find_each do |p|
      p.answers << answers.new
    end
  end
end
