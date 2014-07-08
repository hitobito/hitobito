#  Copyright (c) 2014, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# follow conventions of http://jsonapi.org/
api_response(json, entry) do |person|
  json.href group_person_url(@group, person, format: :json)

  json.extract!(person, :first_name,
                        :last_name,
                        :nickname,
                        :company_name,
                        :company,
                        :email,
                        :address,
                        :zip_code,
                        :town,
                        :country)

  json.picture person.picture_full_url

  details = can?(:show_details, person)
  json.partial! 'contactable/contact_data', contactable: person, only_public: !details

  if details
    json.extract!(person, :birthday,
                          :gender,
                          :additional_information)

    json_extensions json, :details, locals: { show_full: can?(:show_full, person) }

    json.extract!(person, :created_at,
                          :creator_id,
                          :updated_at,
                          :updater_id)
  end

  json.primary_group do
    json.partial! 'groups/link', group: person.primary_group
  end

  json.roles person.filtered_roles(can?(:show_full, person) ? nil : @group),
             partial: 'roles/attrs',
             as: :role

end