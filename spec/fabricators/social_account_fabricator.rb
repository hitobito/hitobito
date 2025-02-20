#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: social_accounts
#
#  id               :integer          not null, primary key
#  contactable_type :string           not null
#  label            :string
#  name             :string           not null
#  public           :boolean          default(TRUE), not null
#  contactable_id   :integer          not null
#
# Indexes
#
#  index_social_accounts_on_contactable_id_and_contactable_type  (contactable_id,contactable_type)
#  social_accounts_search_column_gin_idx                         (search_column) USING gin
#

Fabricator(:social_account) do
  contactable { Fabricate(:person) }
  name { Faker::Internet.user_name }
  label { "faceSpace" }
end
