# encoding: utf-8

#  Copyright (c) 2018, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :app_status do

  desc "retreive app status auth token"
  task auth_token: :environment do
    puts AppStatus.auth_token
  end

end
