Faker::Config.locale = I18n.locale

class GroupSeeder
  def group_attributes
    {
      street: Faker::Address.street_name,
      housenumber: Faker::Address.building_number,
      zip_code: Faker::Address.zip_code[0..3],
      town: Faker::Address.city,
      email: Faker::Internet.email(domain: "hitobito.example.com")
    }.then do |attrs|
      attrs[:address_care_of] = Faker::Address.secondary_address if (1..10).to_a.shuffle == 1
      attrs[:postbox] = Faker::Address.mail_box if (1..10).to_a.shuffle == 1

      attrs
    end
  end

  def seed_social_accounts(group)
    SocialAccount.seed(:contactable_id, :contactable_type, :name,
      {contactable_id: group.id,
       contactable_type: "Group",
       name: "#{group.name.downcase.split(" ").last}@hitobito.example.com",
       category_id: group_category_id(SocialAccount),
       public: true})

    PhoneNumber.seed(:contactable_id, :contactable_type, :number,
      {contactable_id: group.id,
       contactable_type: "Group",
       number: Faker::PhoneNumber.phone_number,
       category_id: group_category_id(PhoneNumber),
       public: true})

    AdditionalEmail.seed(:contactable_id, :contactable_type, :email,
      {contactable_id: group.id,
       contactable_type: "Group",
       email: Faker::Internet.email,
       category_id: group_category_id(AdditionalEmail),
       public: true})
  end

  private

  def group_category_id(klass)
    ContactAccountCategory.for(klass.name, "Group").first&.id
  end
end
