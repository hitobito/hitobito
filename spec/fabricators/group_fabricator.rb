# encoding: utf-8

# == Schema Information
#
# Table name: groups
#
#  id                          :integer          not null, primary key
#  address                     :text(16777215)
#  country                     :string(255)
#  deleted_at                  :datetime
#  description                 :text(16777215)
#  email                       :string(255)
#  lft                         :integer
#  logo                        :string(255)
#  name                        :string(255)      not null
#  require_person_add_requests :boolean          default(FALSE), not null
#  rgt                         :integer
#  short_name                  :string(31)
#  town                        :string(255)
#  type                        :string(255)      not null
#  zip_code                    :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  contact_id                  :integer
#  creator_id                  :integer
#  deleter_id                  :integer
#  layer_group_id              :integer
#  parent_id                   :integer
#  updater_id                  :integer
#
# Indexes
#
#  index_groups_on_layer_group_id  (layer_group_id)
#  index_groups_on_lft_and_rgt     (lft,rgt)
#  index_groups_on_parent_id       (parent_id)
#  index_groups_on_type            (type)
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
