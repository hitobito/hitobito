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
#  event_type               :string
#  multiple_choices         :boolean          default(FALSE), not null
#  question                 :text
#  type                     :string           not null
#  event_id                 :integer
#
# Indexes
#
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

  has_many :answers, dependent: :destroy
  belongs_to :event_question_template, class_name: "Event::QuestionTemplate"

  attribute :type, default: -> { Event::Question::Default.sti_name }
  attr_accessor :skip_add_answer_to_participations

  validates_by_schema

  # validate question presence for admin/non-admin questions separately
  # so we can have different error messages
  validates :question, presence: {message: :admin_blank}, if: :admin?
  validates :question, presence: {message: :application_blank}, unless: :admin?

  before_save :prevent_changes_on_derived, if: :derived?
  before_save :copy_translations_for_derived_question, if: :derived?
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

  def label
    # use safe navigation so not to break records missing the
    # question text created before validation was added
    question&.truncate(30)
  end

  def derived?
    event_question_template_id.present?
  end

  def validate_answer(_answer)
  end

  def before_validate_answer(_answer)
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
      existing_answer = participation.answers.find { _1.question.id == id }

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
    choices.to_s.split(",", -1).collect do |choice|
      choice.gsub(Choice::ESCAPED_SEPARATOR, ",").strip
    end
  end

  # Copy all translations from question template question to new derived question
  # We do this after_save to not having to handle any translation logic in the form
  # where the question and choices are not editable anyways
  def copy_translations_for_derived_question
    [:question, :choices].each do |attribute|
      template_translations = globalize_locales.map {
        [_1.to_s, nil]
      }.to_h.merge(event_question_template.question.send(:"#{attribute}_translations"))
      send(:"#{attribute}_translations=", template_translations)
    end
  end

  # For derived questions we don't want to allow any changes to question or choices
  # We can't use methods like restore_question! here, because globalized changes dirty
  # tracking, whic results in loosing translations
  def prevent_changes_on_derived
    [:question, :choices].each do |attribute|
      send(:"#{attribute}=", event_question_template.question.send(attribute))
    end
  end
end
