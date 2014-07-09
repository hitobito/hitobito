# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ContactSerializer < ApplicationSerializer
  schema do
    json_api_properties

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
  end
end