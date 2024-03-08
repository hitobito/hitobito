#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: groups
#
#  id                                      :integer          not null, primary key
#  address                                 :text(65535)
#  archived_at                             :datetime
#  country                                 :string(255)
#  custom_self_registration_title          :string(255)
#  deleted_at                              :datetime
#  description                             :text(65535)
#  email                                   :string(255)
#  encrypted_text_message_password         :string(255)
#  encrypted_text_message_username         :string(255)
#  letter_address_position                 :string(255)      default("left"), not null
#  lft                                     :integer
#  main_self_registration_group            :boolean          default(FALSE), not null
#  name                                    :string(255)
#  nextcloud_url                           :string(255)
#  privacy_policy                          :string(255)
#  privacy_policy_title                    :string(255)
#  require_person_add_requests             :boolean          default(FALSE), not null
#  rgt                                     :integer
#  self_registration_notification_email    :string(255)
#  self_registration_require_adult_consent :boolean          default(FALSE), not null
#  self_registration_role_type             :string(255)
#  short_name                              :string(31)
#  text_message_originator                 :string(255)
#  text_message_provider                   :string(255)      default("aspsms"), not null
#  town                                    :string(255)
#  type                                    :string(255)      not null
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
