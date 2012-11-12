
@encrypted_password = BCrypt::Password.create("jub42la", cost: 1)

def amount(role_type)
  case role_type.name.demodulize
    when 'Member', 'External' then 5
    when 'Child' then 10
    else 1
    end
end

def person_attributes(role_type)
  first_name = Faker::Name.first_name
  last_name = Faker::Name.last_name
  
  attrs = { 
    first_name: first_name,
    last_name: last_name,
    email: "#{Faker::Internet.user_name("#{first_name} #{last_name}")}@jubla.example.com",
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

def random_date
  from = Time.new(1970)
  to = Time.new(2000)
  Time.at(from + rand * (to.to_f - from.to_f)).to_date
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

Group.root.self_and_descendants.each do |group|
  group.role_types.reject(&:restricted).each do |role_type|
    # set random seed to get the same names over various runs
    # the .hash method does not work as it does not return the same value over various runs.
    srand(role_type.name.bytes.inject(group.id*31 + 11) {|code, b| code ^= b*97 + 5 })
    
    count = amount(role_type)
    count.times do
      p = Person.seed(:email, person_attributes(role_type)).first
      seed_accounts(p, count == 1)
      Role.seed_once(:person_id, :group_id, :type, 
       { person_id: p.id,
         group_id:  group.id,
         type:      role_type.name
       }
      )
    end
  end
end


puzzlers = ['Pascal Zumkehr', 
            'Pascal Simon', 
            'Pierre Fritsch', 
            'Andreas Maierhofer', 
            'Roland Studer']
devs = {'Martin Zust' => 'animation@jublaluzern.ch'}

puzzlers.each do |puz|
  devs[puz] = "#{puz.split.last.downcase}@puzzle.ch"
end


bula = Group.root.children.first
devs.each do |name, email| 
  first, last = name.split
  attrs = { email: email, 
            first_name: first,
            last_name: last,
            encrypted_password: @encrypted_password } 
  Person.seed_once(:email, attrs)
  person = Person.find_by_email(attrs[:email])
  role_attrs = { person_id: person.id, group_id: bula.id, type: Group::FederalBoard::Member.name } 
  Role.seed_once(*role_attrs.keys, role_attrs)
end
