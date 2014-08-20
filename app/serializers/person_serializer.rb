# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Serializes a single person. Expects the following context arguments:
#  * group - The group this person is showed for
class PersonSerializer < ApplicationSerializer
  include ContactableSerializer

  schema do
    details = h.can?(:show_details, item)
    full = h.can?(:show_full, item)

    json_api_properties

    property :href, h.group_person_url(context[:group], item, format: :json)

    map_properties :first_name,
                   :last_name,
                   :nickname,
                   :company_name,
                   :company,
                   :email,
                   :address,
                   :zip_code,
                   :town,
                   :country

    property :picture, item.picture_full_url

    contact_accounts(!details)

    if details
      map_properties :birthday,
                     :gender,
                     :additional_information

      apply_extensions(:details, show_full: full)

      modification_properties
    end

    entity :primary_group, item.primary_group, GroupLinkSerializer
    group_template_link 'people.primary_group'

    entities :roles, item.filtered_roles(full ? nil : context[:group]), RoleSerializer
  end
end
