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

  after_create :add_answer_to_participations

  scope :global, -> { where(event_id: nil) }
  scope :application, -> { where(admin: false) }
  scope :admin, -> { where(admin: true) }


  def choice_items
    choices.to_s.split(',').collect(&:strip)
  end

  def label
    question.truncate(30)
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
