module Seed
  module PersonSeeder

    def seed_all_roles
      Group.root.self_and_descendants.each do |group|
        group.role_types.reject(&:restricted).each do |role_type|
          seed_role_type(group, role_type)
        end
      end
    end

    def seed_role_type(group, role_type)
      # set random seed to get the same names over various runs
      # the .hash method does not work as it does not return the same value over various runs.
      srand(role_type.name.bytes.inject(group.id*31 + 11) {|code, b| code ^= b*97 + 5 })

      count = amount(role_type)
      count.times do
        p = Person.seed(:email, person_attributes(role_type)).first
        seed_accounts(p, count == 1)
        seed_role(p, group, role_type)
      end
    end

    def amount(role_type)
      1
    end

    def person_attributes(role_type)
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name

      attrs = {
        first_name: first_name,
        last_name: last_name,
        email: "#{Faker::Internet.user_name("#{first_name} #{last_name}")}@hitobito.example.com",
        address: Faker::Address.street_address,
        zip_code:  Faker::Address.zip_code,
        town: Faker::Address.city,
        gender: %w(m w).shuffle.first,
        birthday: random_date,
        encrypted_password: @encrypted_password
        }

      if role_type == Role::External
        attrs[:company] = true
        attrs[:company_name] = Faker::Company.name
      else
        attrs[:nickname] = Faker::Lorem.words(1).first.capitalize
      end

      attrs
    end

    def seed_developer(name, email, group, role_type)
      first, last = name.split
      attrs = { email: email,
                first_name: first,
                last_name: last,
                encrypted_password: @encrypted_password }
      Person.seed_once(:email, attrs)
      person = Person.find_by_email(attrs[:email])

      role_attrs = { person_id: person.id, group_id: group.id, type: role_type.sti_name }
      Role.seed_once(*role_attrs.keys, role_attrs)
    end

    def seed_accounts(person, several = false)
      PhoneNumber.seed(:contactable_id, :contactable_type, :label,
        { contactable_id:   person.id,
          contactable_type: person.class.name,
          number:           Faker::PhoneNumber.phone_number,
          label:            Settings.phone_number.predefined_labels.first,
          public:           true }
      )
      if several
        PhoneNumber.seed(:contactable_id, :contactable_type, :label,
          { contactable_id:   person.id,
            contactable_type: person.class.name,
            number:           Faker::PhoneNumber.phone_number,
            label:            Settings.phone_number.predefined_labels.shuffle.first,
            public:           [true, false].shuffle.first }
        )
        SocialAccount.seed(:contactable_id, :contactable_type, :label,
          { contactable_id:   person.id,
            contactable_type: person.class.name,
            name:             Faker::Internet.user_name,
            label:            Settings.social_account.predefined_labels.first,
            public:           [true, false].shuffle.first }
        )
      end
    end

    def seed_role(person, group, role_type)
      Role.seed_once(:person_id, :group_id, :type, { person_id: person.id,
                                                     group_id:  group.id,
                                                     type:      role_type.sti_name })
    end

    def random_date
      from = Time.new(1970)
      to = Time.new(2000)
      Time.at(from + rand * (to.to_f - from.to_f)).to_date
    end
  end
end