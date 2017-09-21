# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Concerns
  module RenderPeopleExports
    extend ActiveSupport::Concern

    def render_pdf(people)
      pdf = generate_pdf(condense_people(people))
      send_data pdf, type: :pdf, disposition: 'inline'
    rescue Prawn::Errors::CannotFit
      redirect_to :back, alert: t('people.pdf.cannot_fit')
    end

    def render_emails(people)
      emails = Person.mailing_emails_for(people)
      render text: emails.join(',')
    end
    
    def render_vcf(people)
      vcf = generate_vcf(people)
      send_data vcf, type: :vcf, disposition: 'inline'
    end

    private

    def condense_people(people)
      if params[:condense_labels] == 'true'
        Person::CondensedContact.condense_list(people)
      else
        people
      end
    end

    def generate_pdf(people)
      Export::Pdf::Labels.new(find_and_remember_label_format).generate(people)
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
end
