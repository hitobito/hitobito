# encoding: utf-8
# == Schema Information
#
# Table name: groups
#
#  id                          :integer          not null, primary key
#  parent_id                   :integer
#  lft                         :integer
#  rgt                         :integer
#  name                        :string(255)      not null
#  short_name                  :string(31)
#  type                        :string(255)      not null
#  email                       :string(255)
#  address                     :string(1024)
#  zip_code                    :integer
#  town                        :string(255)
#  country                     :string(255)
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

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Serializes a single group.
class GroupSerializer < ApplicationSerializer

  include ContactableSerializer

  schema do
    details = h.can?(:show_details, item)

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
