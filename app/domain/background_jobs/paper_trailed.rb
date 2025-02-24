#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module BackgroundJobs
  class PaperTrailed < Delayed::Plugin
    callbacks do |lifecycle|
      lifecycle.around(:invoke_job) do |job, *args, &block|
        mutation_id = "job-#{job.id}"
        whodunnit_type = job.payload_object.class.to_s
        whodunnit = whodunnit_type.underscore
        PaperTrail.request(whodunnit:, controller_info: {mutation_id:, whodunnit_type:}) do
          block.call(job, *args)
        end
      end
    end
  end
end
