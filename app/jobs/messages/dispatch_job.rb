# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class DispatchJob < BaseJob
    self.parameters = [:message_id]

    INTERVAL = 10.seconds

    delegate :update!, :sent_at?, :state, to: :message

    def initialize(message)
      super()
      @message_id = message.id
    end

    def perform
      # TODO what was this for? See 428080fb9b845d463e29bc05a70367ab57f39749
      # It breaks rescheduling.
      # return update!(state: :finished) if sent_at?

      update!(sent_at: Time.current, state: :processing)
      result = message.dispatcher_class.new(message).run
      update!(recipient_count: message.success_count)

      if state == :failed
        nil
      elsif result.finished?
        update!(state: :finished)
      elsif result.needs_reenqueue?
        reenqueue
      end
    end

    def error(job, exception)
      update!(state: :failed)
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
