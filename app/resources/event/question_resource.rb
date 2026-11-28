# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::QuestionResource < ApplicationResource
  self.type = :event_questions

  with_options writable: false, filterable: false, sortable: false do
    attribute :event_id, :integer, filterable: true
    attribute :question, :string
    attribute :choices, :array_of_strings do
      @object.deserialized_choices.map(&:choice)
    end
    attribute :multiple_choices, :boolean
    attribute :required, :boolean
  end

  belongs_to :event

  def base_scope = Event::Question.application.list
end
