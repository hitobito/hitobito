# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

Fabricator(:custom_content) do
  key { sequence(:key) { |i| "key#{i}" } }
  label { sequence(:label) { |i| "label#{i}" } }
  placeholders_optional { "" }
  placeholders_required { "" }
  subject { sequence(:subject) { |i| "Custom Content Subject #{i}" } }
  body { sequence(:body) { |i| "Custom Content Body #{i}" } }
end
