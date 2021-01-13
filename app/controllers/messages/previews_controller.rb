# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class PreviewsController < ApplicationController

    def show
      authorize!(:show, message)
      if recipients.present?
        send_data pdf.render, type: :pdf, disposition: :inline, filename: pdf.filename
      else
        redirect_to  message.path_args, alert: t('.recipients_empty')
      end
    end

    private

    def pdf
      @pdf ||= message.exporter_class.new(message, recipients, preview: true)
    end

    def message
      @message ||= Message.find(params[:message_id])
    end

    def recipients
      person_ids = params[:person_id].to_s.split(',')
      people.where(id: person_ids).exists? ? people.where(id: person_ids) : people.limit(1)
    end

    def people
      message.mailing_list.people
    end

  end
end
