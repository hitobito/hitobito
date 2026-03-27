# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_answers
#
#  id               :integer          not null, primary key
#  answer           :string
#  participation_id :integer          not null
#  question_id      :integer          not null
#
# Indexes
#
#  index_event_answers_on_participation_id_and_question_id  (participation_id,question_id) UNIQUE
#

class Event::Answer < ActiveRecord::Base
  # create events also create a version but we do it in after_create to
  # make the event update
  has_paper_trail on: [:update, :destroy],
    meta: {main_id: ->(a) { a.participation_id },
           main_type: Event::Participation.sti_name}

  belongs_to :participation
  belongs_to :question

  attr_reader :raw_answer

  delegate :admin?, to: :question

  before_validation { question&.before_validate_answer(self) }

  after_create :record_initial_version_as_update

  validates_by_schema
  validates :question_id, uniqueness: {scope: :participation_id}
  validates :answer, presence: {if: lambda do
    question && question.required? && participation.enforce_required_answers
  end}
  validate :validate_with_question

  scope :list, -> {
    joins(:question)
      .merge(Event::Question.list)
      .includes(question: :translations)
      .select("event_answers.*")
  }

  def to_s(format = :default)
    # Used for log, in the log we want to show to what question the answer
    # belongs to. The actual change (answer) is inside the version changelog
    return question.label if format == :long

    answer
  end

  def answer
    super&.gsub(Choice::ESCAPED_SEPARATOR, ",")
  end

  def escaped_answer
    self[:answer]
  end

  def answer=(value)
    @raw_answer = value
    super
  end

  private

  def validate_with_question
    question.validate_answer(self)
  end

  private

  # When a participation is created, we want to show the answer inside the changelog
  # Only update versions show the changeset with our current implementation.
  # We record an update event on a create for event answers.
  def record_initial_version_as_update
    paper_trail.record_update(force: true, in_after_callback: false, is_touch: false)
  end
end
