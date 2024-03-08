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

# Serializes a single group.
class GroupSerializer < ApplicationSerializer

  include ContactableSerializer

  schema do # rubocop:disable Metrics/BlockLength
    details = h.can?(:show_details, Draper.undecorate(item))

    json_api_properties

    property :href, h.group_url(item, format: :json)
    property :group_type, item.klass.label

    map_properties :layer, :name, :short_name, :email

    if item.contact
      entity :contact, item.contact, ContactSerializer
      template_link 'groups.contact',
                    :people,
                    h.group_person_url('{groups.id}', '{groups.contact}', format: :json)
    else
      map_properties :address, :zip_code, :town, :country
    end

    contact_accounts(!details)

    apply_extensions(:attrs)

    if details
      modification_properties
    end

    property :available_roles, (item.model.class.roles.map do |role_class|
      {
        name: role_class.label, # translated class-name
        role_class: role_class.name
      }
    end)

    entity :parent, item.parent, GroupLinkSerializer
    entity :layer_group, item.layer_group, GroupLinkSerializer
    entities :hierarchy, item.hierarchy, GroupLinkSerializer
    entities :children, item.children.without_deleted.order(:lft), GroupLinkSerializer

    group_template_link 'groups.parent'
    group_template_link 'groups.layer_group'
    group_template_link 'groups.hierarchy'
    group_template_link 'groups.children'

    template_link 'groups.people', :people, h.group_people_url('{groups.id}', format: :json)
  end

end
