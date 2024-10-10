# frozen_string_literal: true

#  Copyright (c) 2014-2021, CEVI Regionalverband ZH-SH-GL. This file is part of
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

require "spec_helper"

describe GroupSerializer do
  let(:group) { groups(:top_group).decorate }
  let(:controller) { double.as_null_object }

  let(:serializer) { GroupSerializer.new(group, controller: controller) }
  let(:hash) { serializer.to_hash }

  subject { hash[:groups].first }

  let(:links) { subject[:links] }

  it "has different entities" do
    expect(links[:parent]).to eq(group.parent_id.to_s)
    expect(links).not_to have_key(:children)
    expect(links[:layer_group]).to eq(group.parent_id.to_s)
    expect(links[:hierarchies].size).to eq(2)
  end

  it "does not include deleted children" do
    _ = Fabricate(Group::GlobalGroup.name.to_sym, parent: group)
    b = Fabricate(Group::GlobalGroup.name.to_sym, parent: group)
    b.update!(deleted_at: 1.month.ago)

    expect(links[:children].size).to eq(1)
  end

  it "does include available roles" do
    expect(subject).to have_key(:available_roles)
    expect(subject[:available_roles]).to have(8).items
    expect(subject[:available_roles]).to match_array [
      {name: "External", role_class: "Role::External"},
      {name: "Leader", role_class: "Group::TopGroup::Leader"},
      {name: "Local Guide", role_class: "Group::TopGroup::LocalGuide"},
      {name: "Local Secretary", role_class: "Group::TopGroup::LocalSecretary"},
      {name: "Group Manager", role_class: "Group::TopGroup::GroupManager"},
      {name: "Member", role_class: "Group::TopGroup::Member"},
      {name: "Invisible People Manager", role_class: "Group::TopGroup::InvisiblePeopleManager"},
      {name: "Secretary", role_class: "Group::TopGroup::Secretary"}
    ]
  end
end
