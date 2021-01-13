# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Messages
  class DispatchesController < ApplicationController
    def create
      authorize!(:update, message)
      update_and_enqueue
      redirect_to message.path_args, notice: flash_message
    end

    private

    def flash_message
      t('.success', model_class: message.class.model_name.human)
    end

    def update_and_enqueue
      message.update(
        recipient_count: message.mailing_list.people.size,
        state: :pending,
        sender: current_user
      )
      Messages::DispatchJob.new(message).enqueue!
    end

    def message
      @message ||= Message.find(params[:message_id])
    end
  end
end
