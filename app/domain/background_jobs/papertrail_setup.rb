# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module BackgroundJobs
  class PapertrailSetup < Delayed::Plugin
    callbacks do |lifecycle|
      lifecycle.around(:invoke_job) do |job, *args, &block|
        mutation_id = "job-#{job.payload_object.class}-#{job.id}"
        PaperTrail.request(controller_info: {mutation_id:}) do
          block.call(job, *args)
        end
      end
    end
  end
end
