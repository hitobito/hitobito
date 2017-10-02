# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  question         :string
#  choices          :string
#  multiple_choices :boolean          not null, default(FALSE)
#  required         :boolean          not null, default(FALSE)
#  admin            :boolean          not null, default(FALSE)
#

class Event::Question < ActiveRecord::Base

  belongs_to :event

  has_many :answers, dependent: :destroy

  validates_by_schema
  validate :assert_zero_or_more_than_one_choice

  after_create :add_answer_to_participations

  scope :global, -> { where(event_id: nil) }

  scope :application, -> { where(admin: false) }
  scope :admin, -> { where(admin: true) }


  def choice_items
    choices.to_s.split(',').collect(&:strip)
  end

  private

  def assert_zero_or_more_than_one_choice
    if choice_items.size == 1
      errors.add(:choices, :requires_more_than_one_choice)
    end
  end

  def add_answer_to_participations
    if event
      event.participations.find_each do |p|
        p.answers << answers.new
      end
    end
  end

end
