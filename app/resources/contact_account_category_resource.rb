# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Read-only lookup of the categories a contact account (phone number, additional email,
# additional address, social account) can be assigned to. API clients need it to find the
# instance specific `category_id` when creating contact accounts.
class ContactAccountCategoryResource < ApplicationResource
  primary_endpoint "contact_account_categories", [:index, :show]
  self.acceptable_scopes += %w[people]

  self.type = "contact_account_categories"

  with_options writable: false do
    attribute :key, :string
    attribute :contact_account_type, :string
    attribute :contactable_type, :string
    attribute :name, :string, filterable: false, sortable: false
    attribute :unique_per_contactable, :boolean, filterable: false
    attribute :position, :integer, filterable: false
  end

  def base_scope
    return ContactAccountCategory.none unless scope_accepted?

    ContactAccountCategory
      .includes(:translations)
      .order(*ContactAccountCategory.default_list_order)
  end
end
