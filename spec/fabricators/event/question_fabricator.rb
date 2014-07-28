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

Fabricator(:event_question, class_name: 'Event::Question') do
  event
  question { Faker::Lorem.words.join(' ') + '?' }
end
