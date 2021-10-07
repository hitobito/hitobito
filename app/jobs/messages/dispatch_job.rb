# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class DispatchJob < BaseJob
    self.parameters = [:message_id]

    delegate :update!, :sent_at?, to: :message

    def initialize(message)
      super()
      @message_id = message.id
    end

    def perform
      return update!(state: :finished) if sent_at?

      update!(sent_at: Time.current, state: :processing)
      message.dispatcher_class.new(message).run
      update!(state: :finished) unless message.text_message?
    end

    def error(job, exception)
      update!(state: :failed)
      super
    end

    private

    def recipients
      message.mailing_list.people
    end

    def sender
      message.sender
    end

    def message
      @message ||= Message.find(@message_id)
    end
  end
end
