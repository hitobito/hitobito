#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonIndex; end

ThinkingSphinx::Index.define_partial :person do
  indexes first_name, last_name, company_name, nickname, company, email, sortable: true
  indexes address, zip_code, town, country, birthday, additional_information

  indexes phone_numbers.number, as: :phone_number
  indexes social_accounts.name, as: :social_account
  indexes additional_emails.email, as: :additional_email
end
