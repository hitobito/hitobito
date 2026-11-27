# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Answers to the application questions of an event, submitted via API.
# Choices are referenced by their 0-based position and stored as text in the given locale.
class Event::ApiRegistration::Answers
  attr_reader :event

  def initialize(event, submitted)
    @event = event
    @submitted = Array.wrap(submitted).map { |entry| entry.respond_to?(:to_h) ? entry.to_h : {} }
  end

  def validate(errors)
    validate_questions(errors)
    validate_values(errors)
    validate_required(errors)
  end

  def assign_to(participation, locale)
    participation.enforce_required_answers = true
    participation.init_answers
    I18n.with_locale(locale) do
      values_by_question.each do |question, value|
        answer = participation.answers.find { |a| a.question_id == question.id }
        answer.answer = core_value(question, value)
        question.before_validate_answer(answer)
      end
    end
  end

  private

  def validate_questions(errors)
    question_ids = @submitted.map { |entry| entry.with_indifferent_access[:question_id] }
    question_ids.uniq.each do |id|
      if questions_by_id.exclude?(id.to_s)
        errors.add(:answers, :unknown_question, question_id: id)
      elsif question_ids.count(id) > 1
        errors.add(:answers, :duplicate_question, question_id: id)
      end
    end
  end

  def validate_values(errors)
    values_by_question.each do |question, value|
      next if valid_value?(question, value)

      errors.add(:answers, :invalid_answer, question: question.question)
    end
  end

  def validate_required(errors)
    questions_by_id.each_value do |question|
      next unless question.required?
      next if values_by_question[question].present?

      errors.add(:answers, :required, question: question.question)
    end
  end

  def valid_value?(question, value)
    if choices(question).empty?
      value.is_a?(String)
    elsif checkboxes?(question)
      indices = Array.wrap(value).map { |index| choice_index(question, index) }
      indices.none?(&:nil?) && indices.uniq.size == indices.size
    else
      !choice_index(question, value).nil?
    end
  end

  def choice_index(question, value)
    index = value.is_a?(Integer) ? value : Integer(value.to_s, 10, exception: false)
    index if index && index >= 0 && index < choices(question).size
  end

  def core_value(question, value)
    if choices(question).empty?
      value
    elsif checkboxes?(question)
      Array.wrap(value).map { |index| (choice_index(question, index) + 1).to_s }
    else
      choices(question)[choice_index(question, value)]
    end
  end

  def choices(question)
    question.deserialized_choices.map(&:choice)
  end

  def checkboxes?(question)
    question.multiple_choices? || choices(question).one?
  end

  def values_by_question
    @values_by_question ||= @submitted.each_with_object({}) do |entry, memo|
      entry = entry.with_indifferent_access
      question = questions_by_id[entry[:question_id].to_s]
      memo[question] = entry[:answer] if question
    end
  end

  def questions_by_id
    @questions_by_id ||= event.questions.application.includes(:translations)
      .index_by { |question| question.id.to_s }
  end
end
