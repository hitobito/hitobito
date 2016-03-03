# encoding: utf-8
# == Schema Information
#
# Table name: groups
#
#  id                          :integer          not null, primary key
#  parent_id                   :integer
#  lft                         :integer
#  rgt                         :integer
#  name                        :string           not null
#  short_name                  :string(31)
#  type                        :string           not null
#  email                       :string
#  address                     :string(1024)
#  zip_code                    :integer
#  town                        :string
#  country                     :string
#  contact_id                  :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  deleted_at                  :datetime
#  layer_group_id              :integer
#  creator_id                  :integer
#  updater_id                  :integer
#  deleter_id                  :integer
#  require_person_add_requests :boolean          default(FALSE), not null
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:group) do
  name { Faker::Name.name }
end

Group.all_types.collect { |g| g.name.to_sym }.each do |t|
  Fabricator(t, from: :group, class_name: t)
end
