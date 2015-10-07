# encoding: utf-8
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


#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PhoneNumberSerializer < ContactAccountSerializer
  schema do
    contact_properties
  end
end
