# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:access_token, class_name: :'Doorkeeper::AccessToken') do
  expires_in { 2.hours }
end

Fabricator(:application, class_name: :'Doorkeeper::Application') do
  name  { Faker::Name.name }
  redirect_uri { 'https://app.com/callback' }
end
