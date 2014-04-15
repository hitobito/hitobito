# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

ThinkingSphinx::Index.define_partial :group do
  indexes name, short_name, sortable: true
  indexes email, address, zip_code, town, country

  indexes parent.name, as: :parent_name
  indexes parent.short_name, as: :parent_short_name
  indexes phone_numbers.number, as: :phone_number
  indexes social_accounts.name, as: :social_account
  indexes additional_emails.email, as: :additional_email

  where 'groups.deleted_at IS NULL'
end
