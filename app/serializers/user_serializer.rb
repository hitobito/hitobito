# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UserSerializer < ApplicationSerializer
  schema do
    json_api_properties

    property :href, h.person_home_path(item, only_path: false, format: :json)

    map_properties :first_name,
                   :last_name,
                   :nickname,
                   :company_name,
                   :company,
                   :gender,
                   :email,
                   :authentication_token,
                   :last_sign_in_at,
                   :current_sign_in_at

    entity :primary_group, item.primary_group, GroupLinkSerializer

    template_link('token.regenerate', 'tokens', h.users_token_url(format: :json), method: 'POST')
    template_link('token.delete', 'tokens', h.users_token_url(format: :json), method: 'DELETE')
  end
end
