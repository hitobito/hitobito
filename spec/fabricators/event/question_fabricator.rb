#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_questions
#
#  id                       :integer          not null, primary key
#  admin                    :boolean          default(FALSE), not null
#  choices                  :string
#  disclosure               :string
#  event_type               :string
#  multiple_choices         :boolean          default(FALSE), not null
#  question                 :text
#  type                     :string           not null
#  derived_from_question_id :integer
#  event_id                 :integer
#
# Indexes
#
#  index_event_questions_on_derived_from_question_id  (derived_from_question_id)
#  index_event_questions_on_event_id                  (event_id)
#

Fabricator(:event_question, class_name: "Event::Question") do
  event
  question { Faker::Lorem.words.join(" ") + "?" }
  disclosure { :optional }
end
