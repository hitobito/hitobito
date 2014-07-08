#  Copyright (c) 2014, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

  json.links do
    json.token do
      json.regenerate do
        json.href users_token_url(format: :json)
        json.method 'POST'
      end
      json.delete do
        json.href users_token_url(format: :json)
        json.method 'DELETE'
      end
    end
  end
end