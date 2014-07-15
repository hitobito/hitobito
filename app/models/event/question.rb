# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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
#  multiple_choices :boolean          default(FALSE)
#  required         :boolean
#

class Event::Question < ActiveRecord::Base

  belongs_to :event

  has_many :answers, dependent: :destroy

  validate :assert_zero_or_more_than_one_choice

  scope :global, -> { where(event_id: nil) }


  def choice_items
    choices.to_s.split(',').collect(&:strip)
  end

  private

  def assert_zero_or_more_than_one_choice
    if choice_items.size == 1
      errors.add(:choices, :requires_more_than_one_choice)
    end
  end

end
