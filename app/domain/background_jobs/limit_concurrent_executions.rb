#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module BackgroundJobs
  class LimitConcurrentExecutions < Delayed::Plugin
    callbacks do |lifecycle|
      lifecycle.around(:invoke_job) do |job, *args, &block|
        Instrumentation.new(job, args, &block).run
      end
    end

    class Instrumentation
      def initialize(job, args, &block)
        @job = job
        @args = args
        @block = block
        @job_class = job.payload_object.class.to_s
      end

      def run
        if exceeds_limit?
          reschedule
        else
          execute
        end
      end

      private

      attr_reader :job, :args, :block, :job_class

      def execute
        block.call(job, *args)
      end

      def reschedule
        job.payload_object.enqueue!(run_at: Time.zone.now + settings.reschedule_in)
      end

      def exceeds_limit?
        settings.jobs.include?(job_class) && executing_jobs.count > settings.limit
      end

      def executing_jobs
        Delayed::Job
          .where.not(locked_by: nil, locked_at: nil)
          .where("handler LIKE ?", "%#{job_class}%")
      end

      def settings
        Settings.delayed_jobs.concurrency
      end
    end
  end
end
