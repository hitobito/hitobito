# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  context_type          :string
#  key                   :string           not null
#  label                 :string           not null
#  placeholders_optional :string
#  placeholders_required :string
#  subject               :string
#  context_id            :bigint
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
