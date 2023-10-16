# frozen_string_literal: true

Fabricator(:self_registration_reason) do
  text { Faker::Lorem.unique.sentence }
end
