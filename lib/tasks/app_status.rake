# frozen_string_literal: true

#  Copyright (c) 2018-2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :app_status do
  desc "retreive app status auth token"
  task auth_token: :environment do
    puts AppStatus.auth_token
  end

  namespace :check do
    desc "check truemail status"
    task truemail: :environment do
      if AppStatus::Truemail.new.code == :service_unavailable
        puts "Truemail cannot verify a known-good email anymore."
        exit false
      end
    end

    desc "check if memory usage percentage exceeds configured limit (default 95%). \
            Configuration env var: MEMORY_USAGE_LIMIT_PERCENTAGE"
    task memory_usage: :environment do
      status = AppStatus::MemoryUsage.new

      if status.code == :service_unavailable
        memory_usage_determinable = status.details[:memory_usage_determinable]
        memory_usage_limit_percentage = status.details[:memory_usage_limit_percentage]

        if memory_usage_determinable
          puts "Memory usage exceeds configured limit of #{memory_usage_limit_percentage}"
        else
          puts "Memory usage not determinable because at least one needed cgroup2 file doesnt exist"
        end

        exit false
      end
    end
  end
end
