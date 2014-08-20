# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Serializes a list of people. Expects the following context arguments:
#  * group - The group these people are listed in.
#  * multiple_groups - Whether this list contains people from multiple groups or just from one.
class PeopleSerializer < ApplicationSerializer
  include ContactableSerializer

  schema do
    json_api_properties

    if context[:multiple_groups]
      property :href, h.group_person_url(item.default_group_id, item, format: :json)
    else
      property :href, h.group_person_url(context[:group], item, format: :json)
    end

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

    contact_accounts(!h.index_full_ability?)

    entities :roles,
             item.filtered_roles(context[:multiple_groups] ? nil : context[:group]),
             RoleSerializer
  end
end
