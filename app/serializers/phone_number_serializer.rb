#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: phone_numbers
#
#  id               :integer          not null, primary key
#  contactable_type :string           not null
#  label            :string
#  number           :string           not null
#  public           :boolean          default(TRUE), not null
#  contactable_id   :integer          not null
#
# Indexes
#
#  index_phone_numbers_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#  phone_numbers_search_column_gin_idx                         (search_column) USING gin
#

class PhoneNumberSerializer < ContactAccountSerializer
  schema do
    contact_properties
  end
end
