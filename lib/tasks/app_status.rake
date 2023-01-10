# frozen_string_literal: true

#  Copyright (c) 2018-2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :app_status do

  desc 'retreive app status auth token'
  task auth_token: :environment do
    puts AppStatus.auth_token
  end

  namespace :check do

    desc 'check truemail status'
    task truemail: :environment do
      if AppStatus::Truemail.new.code == :service_unavailable
        exit false
      end
    end

  end
end
