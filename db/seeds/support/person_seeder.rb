# frozen_string_literal: true

#  Copyright (c) 2012-2022, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Faker::Config.locale = I18n.locale

class PersonSeeder

  attr_accessor :encrypted_password

  def initialize
    @encrypted_password = if (dev_pw = ENV['HITOBITO_DEV_PASSWORD'])
                            BCrypt::Password.create(dev_pw, cost: 1)
                          else
                            nil
                          end

    warn <<~MESSAGE if @encrypted_password.nil?
      NO PASSWORD SET FOR SEEDED PEOPLE.
      ==================================

      All people need to use the password-reset to create a password for themselves.

      A default password can be passed in ENV['HITOBITO_DEV_PASSWORD'].
      This also silences this message.
    MESSAGE
  end

  def seed_all_roles
    Group.root.self_and_descendants.each do |group|
      group.role_types.reject(&:restricted?).each do |role_type|
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
    attrs = standard_attributes(Faker::Name.first_name,
                                Faker::Name.last_name)

    if role_type.kind == :external
      attrs[:company] = true
      attrs[:company_name] = Faker::Company.name
    else
      attrs[:nickname] = Faker::Lorem.words(number: 1).first.capitalize
    end
    attrs[:confirmed_at] = Time.now

    attrs
  end

  def standard_attributes(first_name, last_name)
    {
      first_name: first_name,
      last_name: last_name,
      email: "#{Faker::Internet.user_name(specifier: "#{first_name} #{last_name}").parameterize}@hitobito.example.com",
      address: Faker::Address.street_address,
      zip_code:  Faker::Address.zip_code[0..3],
      town: Faker::Address.city,
      gender: %w(m w).shuffle.first,
      birthday: random_date,
      encrypted_password: encrypted_password
    }
  end

  def assign_role_to_root(group, role_type)
    person = Person.find_by(email: Settings.root_email)
    raise "No root-user found. 'rake db:seed' should fix it" unless person

    role_attrs = { person_id: person.id, group_id: group.id, type: role_type.sti_name }
    Role.seed_once(*role_attrs.keys, role_attrs)
  end

  def seed_developer(name, email, group, role_type)
    first, last = name.split
    attrs = standard_attributes(first, last).merge({
      email: email,
      encrypted_password: encrypted_password,
      confirmed_at: Time.now
    }).reject do |key, _value|
      %i(
        address
        zip_code
        town
        gender
        birthday
      ).include? key
    end

    Person.seed_once(:email, attrs)
    person = Person.find_by_email(attrs[:email])

    role_attrs = { person_id: person.id, group_id: group.id, type: role_type.sti_name }
    Role.seed_once(*role_attrs.keys, role_attrs)
  end

  def seed_accounts(person, several = false)
    seed_phone_number(person)
    if several
      seed_additional_emails(person, true)
      seed_phone_number(person, true)
      seed_social_account(person, true)
    end
  end

  def seed_additional_emails(person, shuffle = false)
    seed_account(person,
                 AdditionalEmail,
                 { email: Faker::Internet.safe_email,
                   mailings: [true, false].shuffle.first },
                 Settings.additional_email.predefined_labels,
                 shuffle)
  end

  def seed_phone_number(person, shuffle = false)
    seed_account(person,
                 PhoneNumber,
                 { number: Faker::PhoneNumber.phone_number },
                 Settings.phone_number.predefined_labels,
                 shuffle)
  end

  def seed_social_account(person, shuffle = false)
    seed_account(person,
                 SocialAccount,
                 { name: Faker::Internet.user_name },
                 Settings.social_account.predefined_labels,
                 shuffle)
  end

  def seed_account(person, klass, attrs, labels, shuffle)
    attrs.merge!({ contactable_id:   person.id,
                   contactable_type: person.class.name,
                   label:            shuffle ? labels.shuffle.first : labels.first,
                   public:           shuffle ? [true, false].shuffle.first : true })
    klass.seed(:contactable_id, :contactable_type, :label, attrs)
  end

  # opts is used in wagon to set additional attributes
  def seed_role(person, group, role_type, **opts)
    Role.seed_once(:person_id, :group_id, :type, { person_id: person.id,
                                                   group_id:  group.id,
                                                   type:      role_type.sti_name,
                                                   **opts })
  end

  def random_date
    from = Time.new(1970)
    to = Time.new(2000)
    Time.at(from + rand * (to.to_f - from.to_f)).to_date
  end
end
