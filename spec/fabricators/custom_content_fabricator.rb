# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  key                   :string           not null
#  label                 :string           not null
#  placeholders_optional :string
#  placeholders_required :string
#  subject               :string
#

Fabricator(:custom_content) do
  key { sequence(:key) { |i| "key#{i}" } }
  label { sequence(:label) { |i| "label#{i}" } }
  placeholders_optional { "" }
  placeholders_required { "" }
  subject { sequence(:subject) { |i| "Custom Content Subject #{i}" } }
  body { sequence(:body) { |i| "Custom Content Body #{i}" } }
end
