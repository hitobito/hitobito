# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class DispatchesController < ApplicationController
    def create
      authorize!(:update, message)
      update_and_enqueue
      redirect_to redirect_path, notice: flash_message
    end

    private

    def redirect_path
      case message
      when Message::Letter, Message::LetterWithInvoice
        new_assignment_path(assignment: { attachment_id: message.id,
                                          attachment_type: Message.sti_name },
                            return_url: group_mailing_list_message_path(message.group,
                                                                   message.mailing_list,
                                                                   message)
                            )
      else
        message.path_args
      end
    end

    def flash_message
      t(".success", model_class: message.class.model_name.human)
    end

    def update_and_enqueue
      message.update!(
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
