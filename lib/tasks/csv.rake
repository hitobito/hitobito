# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "faker"
require "bcrypt"
require "csv-safe"

namespace :csv do
  desc "Generates dummy csv file"
  task :generate do # rubocop:disable Rails/RakeEnvironment
    csv_string = CSVSafe.generate do |csv|
      csv << person_attributes.keys
      5.times do
        csv << enhance(person_attributes).values
      end
    end
    File.write("dummy.csv", csv_string)
  end

  # rubocop:disable Rails/TimeZone
  def random_date
    from = Time.new(1970)
    to = Time.new(2000)
    Time.at(from + (rand * (to.to_f - from.to_f))).to_date
  end
  # rubocop:enable Rails/TimeZone

  def person_attributes # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    {
      first_name: first_name,
      last_name: last_name,
      company: Faker::Name.name,
      company_name: Faker::Name.name,
      email: "#{Faker::Internet.user_name("#{first_name} #{last_name}")}@example.com",
      street: Faker::Address.street_name,
      housenumber: Faker::Address.building_number,
      zip_code: Faker::Address.zip_code,
      town: Faker::Address.city,
      gender: %w[m w].sample,
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
    }.then do |attrs|
      attrs[:address_care_of] = Faker::Address.secondary_address if (1..10).to_a.shuffle == 1
      attrs[:postbox] = Faker::Address.mail_box if (1..10).to_a.shuffle == 1

      attrs
    end
  end

  def enhance(person_attributes) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity
    person_attributes.inject({}) do |hash, (k, v)| # rubocop:disable Style/EachWithObject
      hash[k] = v
      case rand(10)
      when 0 then hash[k] = "#{v} "
      when 1 then hash[k] = " #{v}"
      when 2 then hash[k] = " #{v} "
      when 3 then hash[k] = (v[v.size / 2] = "ä"; v) # rubocop:disable Style/Semicolon
      when 4, 5 then hash[k] = nil
      end
      hash
    end
  end
end
