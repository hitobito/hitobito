# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module BackgroundJobs
  class Reloader < Delayed::Plugin
    callbacks do |lifecycle|
      lifecycle.before(:perform) do |*|
        Rails.application.reloader.reload!
      end
    end
  end
end
