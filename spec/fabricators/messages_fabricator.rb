# frozen_string_literal: true

Fabricator(:letter, from: 'Message::Letter') do
  subject { "#{Faker::Superhero.power} #{Faker::Number.number(digits: 4)}" }
  body { Faker::Lorem.sentences }
end
