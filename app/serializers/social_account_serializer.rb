# encoding: utf-8

# == Schema Information
#
# Table name: social_accounts
#
#  id               :integer          not null, primary key
#  contactable_type :string(255)      not null
#  label            :string(255)
#  name             :string(255)      not null
#  public           :boolean          default(TRUE), not null
#  contactable_id   :integer          not null
#
# Indexes
#
#  index_social_accounts_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SocialAccountSerializer < ContactAccountSerializer
  schema do
    contact_properties
  end
end
