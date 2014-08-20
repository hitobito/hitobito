# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'faker'
require 'bcrypt'
require 'csv'


namespace :csv do
  desc "Generates dummy csv file"
  task :generate do
    csv_string = CSV.generate do |csv|
      csv << person_attributes.keys
      5.times do
        csv << enhance(person_attributes).values
      end
    end
    File.write('dummy.csv',csv_string)
  end


  def random_date
    from = Time.new(1970)
    to = Time.new(2000)
    Time.at(from + rand * (to.to_f - from.to_f)).to_date
  end

  # rubocop:disable MethodLength
  def person_attributes
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    {
      first_name: first_name,
      last_name: last_name,
      company: Faker::Name.name,
      company_name: Faker::Name.name,
      email: "#{Faker::Internet.user_name("#{first_name} #{last_name}")}@example.com",
      address: Faker::Address.street_address,
      zip_code:  Faker::Address.zip_code,
      town: Faker::Address.city,
      gender: %w(m w).shuffle.first,
      birthday: random_date.to_s,
      phone_number_andere: Faker::PhoneNumber.phone_number,
      phone_number_arbeit: Faker::PhoneNumber.phone_number,
      phone_number_fax: Faker::PhoneNumber.phone_number,
      phone_number_mobil: Faker::PhoneNumber.phone_number,
      phone_number_mutter: Faker::PhoneNumber.phone_number,
      phone_number_privat: Faker::PhoneNumber.phone_number,
      phone_number_vater: Faker::PhoneNumber.phone_number,
      social_account_skype: Faker::Internet.user_name,
      social_account_msn: Faker::Internet.user_name,
      social_account_webseite: Faker::Internet.domain_name,
      additional_information: Faker::Lorem.paragraph
    }
  end
  # rubocop:enable MethodLength

  def enhance(person_attributes)
    person_attributes.inject({}) do |hash, (k, v)|
      hash[k] = v
      case rand(10)
      when 0 then hash[k] = "#{v} "
      when 1 then hash[k] = " #{v}"
      when 2 then hash[k] = " #{v} "
      when 3 then hash[k] = (v[v.size/2] = "ä"; v)
      when 4 then hash[k] = nil
      when 5 then hash[k] = nil
      end
      hash
    end
  end
end
