#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::QuestionTemplate < ActiveRecord::Base
  belongs_to :question, dependent: :destroy
  belongs_to :group

  def derive_question
    Event::Question.build(question.attributes.excluding("id", "created_at",
      "updated_at")).tap do |derived_question|
      derived_question.event_question_template_id = id
    end
  end
end
