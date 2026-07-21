# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_question_visibilities
#
#  id          :bigint           not null, primary key
#  role_type   :string           not null
#  question_id :bigint
#
# Indexes
#
#  idx_event_question_visibilities_unique            (question_id,role_type) UNIQUE
#  index_event_question_visibilities_on_question_id  (question_id)
#
class Event::QuestionVisibility < ActiveRecord::Base
  belongs_to :question, class_name: "Event::Question", inverse_of: :question_visibilities

  validates_by_schema
  validates :role_type, inclusion: {in: :selectable_role_types}

  def role_class
    role_type.constantize
  end

  def selectable_role_types
    self.class.selectable_role_types_for(event: question.event, admin: question.admin?)
  end

  def self.selectable_role_types_for(event:, admin:) # rubocop:disable Metrics/CyclomaticComplexity
    (event&.role_types || Event.role_types)
      .reject(&:participations_full?)
      .reject { |role| role.participant? && admin }
      .collect(&:sti_name)
  end
end
