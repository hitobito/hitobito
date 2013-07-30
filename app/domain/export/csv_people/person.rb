# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::CsvPeople
  # Attributes of a person, handles associations
  class Person < Hash
    def initialize(person)
      merge!(person.attributes.symbolize_keys)
      merge!(roles: map_roles(person.roles))
      person.phone_numbers.each { |number| merge!(map_object(number)) }
      person.social_accounts.each { |account| merge!(map_object(account)) }
    end

    private
    def map_object(object)
      case object
      when PhoneNumber then { Accounts.phone_numbers.key(object.label) => object.value }
      when SocialAccount then { Accounts.social_accounts.key(object.label) => object.name }
      end
    end

    def map_roles(roles)
      roles.map { |role| "#{role} #{role.group}"  }.join(', ')
    end
  end
end