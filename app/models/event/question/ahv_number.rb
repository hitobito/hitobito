# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  admin            :boolean          default(FALSE), not null
#  choices          :string(255)
#  multiple_choices :boolean          default(FALSE), not null
#  question         :text(65535)
#  required         :boolean          default(FALSE), not null
#  event_id         :integer
#
# Indexes
#
#  index_event_questions_on_event_id  (event_id)
#

class Event::Question::AhvNumber < Event::Question
  def validate_answer(answer)
    validator = AhvNumberValidator.new(attributes: :answer)
    validator.validate(answer)
  end
end
