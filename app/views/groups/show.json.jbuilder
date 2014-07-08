#  Copyright (c) 2014, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

api_response(json, entry) do |group|
  details =  can?(:show_details, group)

  json.href group_url(group, format: :json)
  json.type group.klass.label
  json.layer group.layer

  json.extract!(group, :name,
                       :short_name,
                       :email)

  if group.contact
    json.contact do
      json.id group.contact.id
      json.extract!(group.contact, :first_name,
                                   :last_name,
                                   :nickname,
                                   :company_name,
                                   :company,
                                   :email,
                                   :address,
                                   :zip_code,
                                   :town,
                                   :country)

      json.partial! 'contactable/contact_data', contactable: group.contact, only_public: true
    end
  else
    json.extract!(group, :address,
                         :zip_code,
                         :town,
                         :country)
  end

  json.partial! 'contactable/contact_data', contactable: group, only_public: !details

  json_extensions json, :attrs

  if details
    json.extract!(group, :created_at,
                         :creator_id,
                         :updated_at,
                         :updater_id,
                         :deleted_at,
                         :deleter_id)
  end

  json.parent do
    json.partial! 'groups/link', group: group.parent
  end

  json.layer_group do
    json.partial! 'groups/link', group: group.layer_group
  end

  json.hierarchy do
    json.partial! 'groups/link', collection: group.hierarchy, as: :group
  end

  json.children do
    json.partial! 'groups/link', collection: group.children, as: :group
  end

  json.links do
    json.people group_people_url(group, format: :json)
  end
end
