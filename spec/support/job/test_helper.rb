# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
#
module Job
  module TestHelpers
    extend ActiveSupport::Concern

    included do
      include ActiveJob::TestHelper

      around do |example|
        ActiveJob::Base.queue_adapter = :test
        example.run
        ActiveJob::Base.queue_adapter = :delayed_job
      end
    end
  end
end
