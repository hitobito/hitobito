# == Schema Information
#
# Table name: event_guests
#
#  id                :integer          not null, primary key
#  main_applicant_id :integer          not null
#  first_name        :string
#  last_name         :string
#  nickname          :string
#  company_name      :string
#  company           :boolean
#  email             :string
#  address_care_of   :string
#  street            :string
#  housenumber       :string
#  postbox           :string
#  zip_code          :string
#  town              :string
#  country           :string
#  gender            :string
#  birthday          :date
#  phone_number      :string
#  language          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_event_guests_on_main_applicant_id  (main_applicant_id)
#

#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:event_guest, class_name: "Event::Guest") do
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  nickname { Faker::Name.first_name }
  email { "guest@example.com" }
  main_applicant { Fabricate(:event_participation, participant: Fabricate(:person)) }
end
