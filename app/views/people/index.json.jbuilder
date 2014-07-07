# follow conventions of http://jsonapi.org/

api_response(json, @people) do |person|
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

  json.partial! 'contactable/contact_data', contactable: person, only_public: !index_full_ability?

  json.roles person.filtered_roles(@multiple_groups ? nil : @group),
             partial: 'roles/attrs',
             as: :role
end