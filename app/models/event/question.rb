# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_questions
#
#  id                       :integer          not null, primary key
#  admin                    :boolean          default(FALSE), not null
#  choices                  :string
#  disclosure               :string
#  event_type               :string
#  multiple_choices         :boolean          default(FALSE), not null
#  question                 :text
#  type                     :string           not null
#  derived_from_question_id :integer
#  event_id                 :integer
#
# Indexes
#
#  index_event_questions_on_derived_from_question_id  (derived_from_question_id)
#  index_event_questions_on_event_id                  (event_id)
#

class Event::Question < ActiveRecord::Base
  include Globalized
  include I18nEnums

  self.list_alphabetically = Settings.event.questions.list_alphabetically

  # ensure all translated attributes including subclasses are added here
  # as globalize will add it to the base class' translated_attribute_names
  # anyway and break sti subclasses
  translates :question, :choices

  belongs_to :event
  belongs_to :derived_from_question, class_name: "Event::Question", inverse_of: :derived_questions

  has_many :answers, dependent: :destroy
  # rubocop:todo Layout/LineLength
  has_many :derived_questions, class_name: "Event::Question", foreign_key: :derived_from_question_id,
    # rubocop:enable Layout/LineLength
    dependent: :nullify, inverse_of: :derived_from_question

  DISCLOSURE_VALUES = %w[optional required hidden].freeze
  i18n_enum :disclosure, DISCLOSURE_VALUES, queries: true

  attribute :type, default: -> { Event::Question::Default.sti_name }
  attr_accessor :skip_add_answer_to_participations

  validates_by_schema

  # validate question presence for admin/non-admin questions separately
  # so we can have different error messages
  validates :question, presence: {message: :admin_blank}, if: :admin?
  validates :question, presence: {message: :application_blank}, unless: :admin?
  validates :disclosure, presence: true, unless: :global?
  validates :derived_from_question_id, uniqueness: {scope: :event_id}, allow_blank: true,
    if: :event_id

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

  def derive(disclosure: nil)
    return unless global? # prevent deriving questions that are attached to an event

    Event::Question.build(attributes.excluding("id")).tap do |derived_question|
      derived_question.derived_from_question = self
      derived_question.disclosure = disclosure if disclosure.present?
    end
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

  # Seed global questions and make sure the same question does not get seeded twice.
  # In case a global question needs to be changed, make sure to create a migration
  # accordingly and change the seed at the same time.
  # Useful options for global questions are:
  # rubocop:todo Layout/LineLength
  # - `translation_attributes`: seed all translations at creation. `[{ locale: :de, question: "...", choices: "..." }]`
  # rubocop:enable Layout/LineLength
  # - `type`: STI-name of question type
  # rubocop:todo Layout/LineLength
  # - `event_type`: STI-name of Event, on which the global question should be applied. `nil` will apply to all events.
  # rubocop:enable Layout/LineLength
  # rubocop:todo Layout/LineLength
  # - `disclosure`: specifies if question is required, optional or hidden. `nil` will force choice at event creation.
  # rubocop:enable Layout/LineLength
  def self.seed_global(attributes)
    questions = [attributes[:question],
      attributes[:translation_attributes]&.pluck(:question)].flatten.compact_blank
    return if includes(:translations).where(event_id: nil, question: questions).exists?

    Event::Question.transaction do
      new(attributes.except(:translation_attributes)).tap do |question|
        attributes[:translation_attributes]&.each do |translation_attributes|
          question.attributes = translation_attributes.slice(:locale,
            *Event::Question.translated_attribute_names)
        end
        question.save!
      end
    end
  end

  def deserialized_choices
    # Adds the locale to the choice items grouped by choice
    # Example: [["Ja", "Yes"], ["Nein", "No"]]
    # -> [{de: "Ja", en: "Yes"}, {de: "Nein", en: "No"}]
    choice_items_by_choice_with_locales = choice_items_by_choice.map do |choice_translations|
      Globalized.languages.zip(choice_translations).to_h
    end

    choice_items_by_choice_with_locales.map do |choice_translations|
      Choice.new(choice_translations)
    end
  end

  # Serializes the choices by grouping them by translation and then saving them as
  # comma separated string.
  # Commas in the actual text of the choices are escaped before saving to not mess
  # with the deserialization.
  # Choices where all translations are empty are ignored.
  #
  # Example:
  # { choices_attributes:
  #   { 1: { choice: "Ja", choice_en: "Yes" }, 2: { choice: "Nein", choice_en: "No" } }
  # }
  # -> choices: "Ja,Nein"
  # -> choices_en: "Yes,No"
  def choices_attributes=(attributes)
    attributes.filter! { |_, v| [1, "1", true, "true"].exclude?(v.delete("_destroy")) }
    choice_items_by_translation =
      attributes.values.map(&:values).filter { |v| v.any?(&:present?) }.transpose

    languages = [I18n.locale] + Globalized.additional_languages
    languages.zip(choice_items_by_translation).each do |lang, choices|
      send(:"choices_#{lang}=", escaped_choices_string(choices))
    end
  end

  def self.reflect_on_all_associations
    super + [Choice::Reflection.new]
  end

  def self.reflect_on_association(association)
    return super unless association == :choices

    Choice::Reflection.new
  end

  private

  def add_answer_to_participations
    return if event.blank? || skip_add_answer_to_participations

    event.participations.find_each do |participation|
      existing_answer = participation.answers.find { _1.question_id == derived_from_question_id }

      if existing_answer
        existing_answer.update(question: self)
      else
        participation.answers << answers.new
      end
    end
  end

  # Regroups the choice items to be grouped by choice instead of by translation.
  # If there is not the same amount of choices in all languages they are filled up
  # with empty strings.
  # Example: [["Ja", "Nein"], ["Yes", "No"]]
  # -> [["Ja", "Yes"], ["Nein", "No"]]
  def choice_items_by_choice
    choice_items_by_translation = Globalized.languages.map do |lang|
      choices_in_lang = send(:"choices_#{lang}")
      unescaped_choices(choices_in_lang)
    end

    normalize_2d_array(choice_items_by_translation).transpose
  end

  # Normalizes an array of subarrays to make all subarrays the size of the
  # biggest subarray so transposing is possible.
  def normalize_2d_array(array)
    max_subarray_length = array.max_by(&:length).length
    array.map do |sub_array|
      next Array.new(max_subarray_length, "") if sub_array.empty?

      sub_array.in_groups_of(max_subarray_length, "").flatten
    end
  end

  # Escapes all commas in the choices before joining them by comma. The escaping is done so
  # choices can include commas in the text without breaking the serialization and deserialization.
  def escaped_choices_string(choices)
    choices.to_a.collect { |choice| choice.gsub(",", Choice::ESCAPED_SEPARATOR) }.join(",")
  end

  # Splits the comma separated choices by comma and then unescapes all commas in the
  # actual text of the choices. These are escaped from the user input before saving
  # so we can deserialize the choices correctly.
  def unescaped_choices(choices)
    choices.to_s.split(",", -1).collect { |choice| choice.gsub(Choice::ESCAPED_SEPARATOR, ",").strip }
  end
end
