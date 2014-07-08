#  Copyright (c) 2014, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# follow conventions of http://jsonapi.org/
api_response(json, @people) do |person|
  if @multiple_groups
    json.href group_person_path(person.default_group_id, person, format: :json)
  else
    json.href group_person_path(@group, person, format: :json)
  end

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

  json.partial! 'contactable/contact_data', contactable: person, only_public: !index_full_ability?

  json.roles person.filtered_roles(@multiple_groups ? nil : @group),
             partial: 'roles/attrs',
             as: :role
end