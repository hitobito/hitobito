# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class DispatchJob < BaseJob
    self.parameters = [:message_id]
    self.max_run_time = 24.hours

    INTERVAL = 10.seconds

    def initialize(message)
      super()
      @message_id = message.id
    end

    def perform
      message.update!(sent_at: Time.current, state: :processing)
      result = message.dispatcher_class.new(message).run
      message.update!(recipient_count: message.success_count)

      if message.state == :failed
        nil
      elsif result.finished?
        message.update!(state: :finished)
      elsif result.needs_reenqueue?
        reenqueue
      end
    end

    def error(job, exception)
      message.update!(state: :failed)
      super
    end

    private

    def sender
      message.sender
    end

    def message
      @message ||= Message.find(@message_id)
    end

    def reenqueue
      enqueue!(run_at: next_run)
    end

    def next_run
      job = delayed_jobs.first
      if job
        [Time.zone.now, job.run_at + INTERVAL].max
      else
        INTERVAL.from_now
      end
    end
  end
end
