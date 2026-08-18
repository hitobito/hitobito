# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ContactAccountCategoriesController < SimpleCrudController
  self.permitted_attrs = [:key, :contact_account_type, :contactable_type,
    :unique_per_contactable, :used_for_invoices, :position, :name]

  self.sort_mappings = {name: "contact_account_category_translations.name"}
end
