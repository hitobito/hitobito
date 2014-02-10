# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::People
  # Attributes of a person, handles associations
  class PersonRow < Export::Csv::Base::Row

    self.dynamic_attributes = { /^phone_number_/ => :phone_number_attribute,
                                /^social_account_/ => :social_account_attribute }

    def roles
      entry.roles.map { |role| "#{role} #{role.group}"  }.join(', ')
    end

    private

    def phone_number_attribute(attr)
      phone = entry.phone_numbers.find { |e| Accounts.phone_numbers.key(e.label) == attr }
      phone.try(:value)
    end

    def social_account_attribute(attr)
      account = entry.social_accounts.find { |e| Accounts.social_accounts.key(e.label) == attr }
      account.try(:name)
    end

  end
end
