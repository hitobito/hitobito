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

Fabricator(:event_answer, class_name: "Event::Answer") do
  participation
  question
  answer { Faker::Lorem.words.join(" ") + "?" }
end
