# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists
  module Messages
    class DispatchesController < ApplicationController
      def create
        authorize!(:update, message)
        message.dispatch! if message.text_message?
        redirect_to redirect_path, flash_message
      end

      private

      def redirect_path
        case message
        when Message::Letter, Message::LetterWithInvoice
          new_assignment_path(
            assignment: {attachment_id: message.id, attachment_type: Message.sti_name},
            return_url: message_path
          )
        else
          message_path
        end
      end

      def message_path
        group_mailing_list_message_path(message.group, message.mailing_list, message)
      end

      def flash_message
        case message
        when Message::Letter, Message::LetterWithInvoice
          {alert: t(".alert.#{message_model_name}")}
        when Message::TextMessage
          {notice: t(".success.#{message_model_name}")}
        end
      end

      def message_model_name
        message.class.model_name.to_s.underscore
      end

      def message
        @message ||= Message.find(params[:message_id])
      end
    end
  end
end
