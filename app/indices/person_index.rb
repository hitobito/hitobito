#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonIndex; end

ThinkingSphinx::Index.define_partial :person do
  indexes first_name, last_name, company_name, nickname, company, email, sortable: true
  indexes address_care_of, street, housenumber, postbox
  indexes address # TODO: remove when cleaning structured_addresses migration
  indexes zip_code, town, country, additional_information

  # sphinx can not search for date
  indexes "DATE_FORMAT(people.birthday, '%d.%m.%Y')", as: :birthday_string

  indexes phone_numbers.number, as: :phone_number
  indexes social_accounts.name, as: :social_account
  indexes additional_emails.email, as: :additional_email
end
