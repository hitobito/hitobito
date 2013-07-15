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