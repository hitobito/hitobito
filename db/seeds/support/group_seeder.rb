
Faker::Config.locale = I18n.locale

class GroupSeeder

  def group_attributes
    {
      street: Faker::Address.street_name,
      housenumber: Faker::Address.building_number,
      zip_code: Faker::Address.zip_code[0..3],
      town: Faker::Address.city,
      email: Faker::Internet.email
    }.then do |attrs|
      attrs[:address_care_of] = Faker::Address.secondary_address if (1..10).to_a.shuffle == 1
      attrs[:postbox] = Faker::Address.mail_box if (1..10).to_a.shuffle == 1

      attrs
    end
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

    AdditionalEmail.seed(:contactable_id, :contactable_type, :email,
      { contactable_id:   group.id,
        contactable_type: 'Group',
        email:            Faker::Internet.email,
        label:            Settings.additional_email.predefined_labels.first,
        public:           true }
    )
  end
end
