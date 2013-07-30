# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RenderPeopleExports

  def render_pdf(people)
    label_format = LabelFormat.find(params[:label_format_id])
    unless current_user.last_label_format_id == label_format.id
      current_user.update_column(:last_label_format_id, label_format.id)
    end

    pdf = Export::PdfLabels.new(label_format).generate(people)
    send_data pdf, type: :pdf, disposition: 'inline'
  end

  def render_emails(people)
    text = people.collect(&:email).compact.join(',')
    render text: text
  end

end