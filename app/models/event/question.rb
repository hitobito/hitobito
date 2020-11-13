# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  question         :string(255)
#  choices          :string(255)
#  multiple_choices :boolean          default(FALSE), not null
#  required         :boolean          default(FALSE), not null
#  admin            :boolean          default(FALSE), not null
#

class Event::Question < ActiveRecord::Base

  belongs_to :event
  has_many :answers, dependent: :destroy

  validates_by_schema
  validate :assert_number_of_choices

  before_validation :make_choices_checkboxes
  after_create :add_answer_to_participations

  scope :global, -> { where(event_id: nil) }
  scope :application, -> { where(admin: false) }
  scope :admin, -> { where(admin: true) }


  def choice_items
    # return choices if checkbox # if this active, adapt the validation.
    choices.to_s.split(',').collect(&:strip)
  end

  def label
    question.truncate(30)
  end

  private

  def make_choices_checkboxes
    return true if multiple_choices

    self.multiple_choices = true if checkbox
  end

  def assert_number_of_choices
    if checkbox
      assert_exactly_one_choice
    else
      assert_zero_or_more_than_one_choice
    end
  end

  def assert_exactly_one_choice
    if choice_items.size != 1
      errors.add(:choices, :requires_exactly_one_choice)
    end
  end

  def assert_zero_or_more_than_one_choice
    if choice_items.size == 1
      errors.add(:choices, :requires_more_than_one_choice)
    end
  end

  def add_answer_to_participations
    return unless event

    event.participations.find_each do |p|
      p.answers << answers.new
    end
  end

end
