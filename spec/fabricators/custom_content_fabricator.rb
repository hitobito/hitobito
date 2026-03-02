# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  key                   :string           not null
#  placeholders_required :string
#  placeholders_optional :string
#  context_type          :string
#  context_id            :integer
#
# Indexes
#
#  index_custom_contents_on_context  (context_type,context_id)
#

Fabricator(:custom_content) do
  key { sequence(:key) { |i| "key#{i}" } }
  label { sequence(:label) { |i| "label#{i}" } }
  placeholders_optional { "" }
  placeholders_required { "" }
  subject { sequence(:subject) { |i| "Custom Content Subject #{i}" } }
  body { sequence(:body) { |i| "Custom Content Body #{i}" } }
end
