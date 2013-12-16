
Faker::Config.locale = I18n.locale

class GroupSeeder

  def group_attributes
    { short_name: ('A'..'Z').to_a.sample(2).join,
      address: Faker::Address.street_address,
      zip_code: Faker::Address.zip,
      town: Faker::Address.city,
      email: Faker::Internet.safe_email
    }
  end

  def seed_social_accounts(group)
    SocialAccount.seed(:contactable_id, :contactable_type, :name,
      { contactable_id:   group.id,
        contactable_type: 'Group',
        name:             "#{group.name.downcase.split(' ').last}@hitobito.example.com",
        label:            'E-Mail',
        public:           true }
    )

    PhoneNumber.seed(:contactable_id, :contactable_type, :number,
      { contactable_id:   group.id,
        contactable_type: 'Group',
        number:           Faker::PhoneNumber.phone_number,
        label:            Settings.phone_number.predefined_labels.first,
        public:           true }
    )
  end
end