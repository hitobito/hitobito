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