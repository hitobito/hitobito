# frozen_string_literal: true

Fabricator(:tag, from: "ActsAsTaggableOn::Tag") do
  name { "#{Faker::Superhero.power} #{Faker::Number.number(4)}" }
end
