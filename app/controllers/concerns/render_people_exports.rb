# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Concerns
  module RenderPeopleExports

    def render_pdf(people)
      label_format = LabelFormat.find(params[:label_format_id])
      unless current_user.last_label_format_id == label_format.id
        current_user.update_column(:last_label_format_id, label_format.id)
      end

      pdf = Export::Pdf::Labels.new(label_format).generate(people)
      send_data pdf, type: :pdf, disposition: 'inline'
    end

    def render_emails(people)
      emails = Person.mailing_emails_for(people)
      render text: emails.join(',')
    end

  end
end
