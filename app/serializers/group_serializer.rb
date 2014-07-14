# encoding: utf-8

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
    entities :children, item.children, GroupLinkSerializer

    group_template_link 'groups.parent'
    group_template_link 'groups.layer_group'
    group_template_link 'groups.hierarchy'
    group_template_link 'groups.children'

    template_link 'groups.people', :people, h.group_people_url('{groups.id}', format: :json)
  end

end