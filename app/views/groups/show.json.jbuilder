api_response(json, entry) do |group|
  details =  can?(:show_details, group)

  json.href group_url(group, format: :json)
  json.type group.klass.label

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

  json.layer do
    json.partial! 'groups/link', group: group.layer_group
  end

  json.children do
    json.partial! 'groups/link', collection: group.children, as: :group
  end
end
