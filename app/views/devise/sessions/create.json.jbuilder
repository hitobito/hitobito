# follow conventions of http://jsonapi.org/

api_response(json, @person, :people) do |person|
  json.href person_home_path(person, only_path: false, format: :json)

  json.extract!(person, :first_name,
                        :last_name,
                        :nickname,
                        :company_name,
                        :company,
                        :gender,
                        :email,
                        :authentication_token,
                        :last_sign_in_at,
                        :current_sign_in_at)

  json.primary_group do
    json.partial! 'groups/link', group: person.primary_group
  end
end