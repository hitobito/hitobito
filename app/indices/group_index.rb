#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module GroupIndex; end

ThinkingSphinx::Index.define_partial :group do
  indexes name, short_name, sortable: true
  indexes email, zip_code, town, country

  # Somehow, these 4 columns are not recognized automatically
  indexes "#{Group.table_name}.address_care_of", as: :address_care_of
  indexes "#{Group.table_name}.street", as: :street
  indexes "#{Group.table_name}.housenumber", as: :housenumber
  indexes "#{Group.table_name}.postbox", as: :postbox

  indexes address # TODO: remove when cleaning structured_addresses migration

  indexes parent.name, as: :parent_name
  indexes parent.short_name, as: :parent_short_name
  indexes phone_numbers.number, as: :phone_number
  indexes social_accounts.name, as: :social_account
  indexes additional_emails.email, as: :additional_email

  # this is inserted verbatim and not auto-quoted
  where "#{Group.quoted_table_name}.deleted_at IS NULL"
end
