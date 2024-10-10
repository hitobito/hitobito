#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: groups
#
#  id                                      :integer          not null, primary key
#  address                                 :string(1024)
#  address_care_of                         :string
#  archived_at                             :datetime
#  country                                 :string
#  custom_self_registration_title          :string
#  deleted_at                              :datetime
#  description                             :text
#  email                                   :string
#  encrypted_text_message_password         :string
#  encrypted_text_message_username         :string
#  housenumber                             :string(20)
#  letter_address_position                 :string           default("left"), not null
#  lft                                     :integer
#  main_self_registration_group            :boolean          default(FALSE), not null
#  name                                    :string
#  nextcloud_url                           :string
#  postbox                                 :string
#  privacy_policy                          :string
#  privacy_policy_title                    :string
#  require_person_add_requests             :boolean          default(FALSE), not null
#  rgt                                     :integer
#  self_registration_notification_email    :string
#  self_registration_require_adult_consent :boolean          default(FALSE), not null
#  self_registration_role_type             :string
#  short_name                              :string(31)
#  street                                  :string
#  text_message_originator                 :string
#  text_message_provider                   :string           default("aspsms"), not null
#  town                                    :string
#  type                                    :string           not null
#  zip_code                                :integer
#  created_at                              :datetime
#  updated_at                              :datetime
#  contact_id                              :integer
#  creator_id                              :integer
#  deleter_id                              :integer
#  layer_group_id                          :integer
#  parent_id                               :integer
#  updater_id                              :integer
#
# Indexes
#
#  index_groups_on_layer_group_id  (layer_group_id)
#  index_groups_on_lft_and_rgt     (lft,rgt)
#  index_groups_on_parent_id       (parent_id)
#  index_groups_on_type            (type)
#

Fabricator(:group) do
  name { Faker::Name.name }
end

Group.all_types.collect { |g| g.name.to_sym }.each do |t|
  Fabricator(t, from: :group, class_name: t)
end
