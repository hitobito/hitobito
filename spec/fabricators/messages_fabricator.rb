# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:letter, from: 'Message::Letter') do
  subject { "#{Faker::Superhero.power} #{Faker::Number.number(digits: 4)}" }
  body { Faker::Lorem.sentences }
end

Fabricator(:text_message, from: 'Message::TextMessage') do
  text { Faker::Lorem.sentence(word_count: 3) }
end
