# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RenderPeopleExports
  extend ActiveSupport::Concern

  def render_pdf(people, group = nil)
    pdf = generate_pdf(people, group)
    send_data pdf, type: :pdf, disposition: 'inline'
  rescue Prawn::Errors::CannotFit
    redirect_back(fallback_location: group_people_path(group, returning: true),
                  alert: t('people.pdf.cannot_fit'))
  end

  def render_emails(people, separator)
    emails = Person.mailing_emails_for(people)
    render plain: emails.join(separator)
  end

  def render_vcf(people)
    vcf = generate_vcf(people)
    send_data vcf, type: :vcf, disposition: 'inline'
  end

  def render_pdf_in_background(people, group, filename)
    with_async_download_cookie(:pdf, filename) do |filename|
      Export::LabelsJob.new(:pdf,
                            current_user.id,
                            people.pluck(:id),
                            group.id,
                            params.slice(:label_format_id, :household)
                                  .merge(filename: filename)).enqueue!
    end
  end

  private

  def generate_pdf(people, group)
    if params[:label_format_id]
      household = true?(params[:household])
      Export::Pdf::Labels.new(find_and_remember_label_format).generate(people, household)
    else
      Export::Pdf::List.render(people, group)
    end
  end

  def generate_vcf(people)
    Export::Vcf::Vcards.new.generate(people)
  end

  def find_and_remember_label_format
    LabelFormat.find(params[:label_format_id]).tap do |label_format|
      unless current_user.last_label_format_id == label_format.id
        current_user.update_column(:last_label_format_id, label_format.id)
      end
    end
  end

end
