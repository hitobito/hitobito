# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: phone_numbers
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string           not null
#  number           :string           not null
#  label            :string
#  public           :boolean          default(TRUE), not null
#

Fabricator(:phone_number) do
  contactable { Fabricate(:person) }
  number { Faker::PhoneNumber.phone_number }
  label { Settings.phone_number.predefined_labels.shuffle.first }
end
