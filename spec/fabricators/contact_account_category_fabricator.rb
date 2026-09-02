# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:contact_account_category) do
  contact_account_type { "PhoneNumber" }
  contactable_type { "Person" }
  key { sequence(:contact_account_category_key) { |i| "key#{i}" } }
  name { sequence(:contact_account_category_name) { |i| "Category #{i}" } }
end
