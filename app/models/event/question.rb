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

  # ensure all translated attributes including subclasses are added here
  # as globalize will add it to the base class' translated_attribute_names
  # anyway and break sti subclasses
  translates :question, :choices

  belongs_to :event
  belongs_to :derived_from_question, class_name: "Event::Question", inverse_of: :derived_questions

  has_many :answers, dependent: :destroy
  has_many :derived_questions, class_name: "Event::Question", foreign_key: :derived_from_question_id,
    dependent: :nullify, inverse_of: :derived_from_question

  DISCLOSURE_VALUES = %w[optional required hidden].freeze
  i18n_enum :disclosure, DISCLOSURE_VALUES, queries: true

  attribute :type, default: -> { Event::Question::Default.sti_name }

  validates_by_schema

  # validate question presence for admin/non-admin questions separately
  # so we can have different error messages
  validates :question, presence: {message: :admin_blank}, if: :admin?
  validates :question, presence: {message: :application_blank}, unless: :admin?
  validates :disclosure, presence: true, unless: :global?
  validates :derived_from_question_id, uniqueness: {scope: :event_id}, allow_blank: true, if: :event_id

  before_validation :assign_derived_attributes, on: :create, if: :derived?
  after_create :add_answer_to_participations

  scope :global, -> { where(event_id: nil) }
  scope :application, -> { where(admin: false) }
  scope :admin, -> { where(admin: true) }

  def required_attrs
    [
      # needed for the required attribute mark in forms
      # as the relevant validation is conditional
      :question, :disclosure
    ]
  end

  def derive
    return unless global? # prevent deriving questions that are attached to an event

    dup.tap { |derived_question| derived_question.derived_from_question = self }
  end

  # most attributes of global questions must not be overriden by derived questions
  def assign_derived_attributes
    return if derived_from_question.blank?

    keep_attributes = %w[id event_id disclosure derived_from_question_id]
    assign_attributes(derived_from_question.attributes.except(*keep_attributes))
  end

  def label
    # use safe navigation so not to break records missing the
    # question text created before validation was added
    question&.truncate(30)
  end

  def global?
    event.blank?
  end

  def derived?
    derived_from_question_id.present?
  end

  def validate_answer(_answer)
  end

  def before_validate_answer(_answer)
  end

  def derive_for_existing_events
    existing_event_ids = Event.where.not(id: derived_questions.pluck(:event_id)).pluck(:id)

    Event::Question.transaction do
      existing_event_ids.map do |event_id|
        derive&.tap do |derived_question|
          derived_question.update!(event_id: event_id)
          Event::Answer.joins(:participation).where(participation: {event_id: event_id}, question_id: id)
            .update_all(question_id: derived_question.id)
        end
      end.compact
    end
  end

  # Seed global questions and make sure the same question does not get seeded twice.
  # In case a global question needs to be changed, make sure to create a migration
  # accordingly and change the seed at the same time.
  # Useful options for global questions are:
  # - `translation_attributes`: seed all translations at creation. `[{ locale: :de, question: "...", choices: "..." }]`
  # - `type`: STI-name of question type
  # - `event_type`: STI-name of Event, on which the global question should be applied. `nil` will apply to all events.
  # - `disclosure`: specifies if question is required, optional or hidden. `nil` will force choice at event creation.
  def self.seed_global(attributes)
    questions = [attributes[:question], attributes[:translation_attributes]&.pluck(:question)].flatten.compact_blank
    return if includes(:translations).where(event_id: nil, question: questions).exists?

    Event::Question.transaction do
      new(attributes.except(:translation_attributes)).tap do |question|
        attributes[:translation_attributes]&.each do |translation_attributes|
          question.attributes = translation_attributes.slice(:locale, *Event::Question.translated_attribute_names)
        end
        question.save!
      end
    end
  end

  private

  def add_answer_to_participations
    return unless event

    event.participations.find_each do |participation|
      existing_answer = participation.answers.find { _1.question_id == derived_from_question_id }

      if existing_answer
        existing_answer.update(question: self)
      else
        participation.answers << answers.new
      end
    end
  end
end
