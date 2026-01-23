#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_guests
#
#  id                :bigint           not null, primary key
#  address_care_of   :string
#  birthday          :date
#  company           :boolean
#  company_name      :string
#  country           :string
#  email             :string
#  first_name        :string
#  gender            :string
#  housenumber       :string
#  language          :string
#  last_name         :string
#  nickname          :string
#  phone_number      :string
#  postbox           :string
#  street            :string
#  town              :string
#  zip_code          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  main_applicant_id :bigint           not null
#
# Indexes
#
#  index_event_guests_on_main_applicant_id  (main_applicant_id)
#
Fabricator(:event_guest, class_name: "Event::Guest") do
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  nickname { Faker::Name.first_name }
  email { "guest@example.com" }
  main_applicant { Fabricate(:event_participation, participant: Fabricate(:person)) }
end
