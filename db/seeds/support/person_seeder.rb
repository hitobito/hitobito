
Faker::Config.locale = I18n.locale

class PersonSeeder

  attr_accessor :encrypted_password

  def initialize
    @encrypted_password = BCrypt::Password.create("hito42bito", cost: 1)
  end

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
    attrs = standard_attributes(Faker::Name.first_name,
                                Faker::Name.last_name)

    if role_type.affiliate
      attrs[:company] = true
      attrs[:company_name] = Faker::Company.name
    else
      attrs[:nickname] = Faker::Lorem.words(1).first.capitalize
    end

    attrs
  end

  def standard_attributes(first_name, last_name)
    {
      first_name: first_name,
      last_name: last_name,
      email: "#{Faker::Internet.user_name("#{first_name} #{last_name}")}@hitobito.example.com",
      address: Faker::Address.street_address,
      zip_code:  Faker::Address.zip_code,
      town: Faker::Address.city,
      gender: %w(m w).shuffle.first,
      birthday: random_date,
      encrypted_password: encrypted_password
    }
  end

  def seed_developer(name, email, group, role_type)
    first, last = name.split
    attrs = { email: email,
              first_name: first,
              last_name: last,
              encrypted_password: encrypted_password }
    Person.seed_once(:email, attrs)
    person = Person.find_by_email(attrs[:email])

    role_attrs = { person_id: person.id, group_id: group.id, type: role_type.sti_name }
    Role.seed_once(*role_attrs.keys, role_attrs)
  end

  def seed_accounts(person, several = false)
    seed_phone_number(person)
    if several
      seed_phone_number(person, true)
      seed_social_account(person, true)
    end
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