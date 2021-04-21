# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class PreviewsController < ApplicationController
    include RenderMessagesExports

    def show
      authorize!(:show, message)
      render_pdf(message, preview: true)
      # TODO handle case with no recipients
      # redirect_to  message.path_args, alert: t('.recipients_empty')
    end

    private

    def message
      @message ||= Message.find(params[:message_id])
    end
  end
end
