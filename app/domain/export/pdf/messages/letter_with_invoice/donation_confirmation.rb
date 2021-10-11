# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::LetterWithInvoice
  class DonationConfirmation < Export::Pdf::Messages::Letter::Section

    def initialize(pdf, letter, recipient, options)
      super(pdf, letter, options)
      pdf.start_new_page
      @recipient = recipient.person
      @letter = letter
    end

    def render
      header
      title
      pdf.move_down 14
      donation_confirmation_text
      text(last_year_donation_amount)
    end

    private

    def header
      stamped(:donation_confirmation_header)
      pdf.move_down 8
      text(salutation)
      stamped(:donation_confirmation_content)
    end

    def title
      stamped(:donation_confirmation_title)
      pdf.stroke_horizontal_rule
    end

    def salutation
      Salutation.new(@recipient, letter.salutation).value + break_line
    end

    def donation_confirmation_content
      text I18n.t('messages.export.section.donation_confirmation.acknowledgement') + break_line
    end

    def donation_confirmation_header
      layer_name = @letter.group.layer_group.name
      text I18n.t('messages.export.section.donation_confirmation.header', organisation: layer_name),
           style: :bold,
           size: 14
    end

    def donation_confirmation_title
      text I18n.t('messages.export.section.donation_confirmation.title', year: 1.year.ago.year),
           style: :bold
    end

    def donation_confirmation_text
      stamped(:donation_confirmation_year_info)
      pdf.move_down 10
      text(recipient_address)
      pdf.move_down 10
      stamped(:donation_confirmation_received_amount_info)
      pdf.move_down 10
    end

    def donation_confirmation_year_info
      text(I18n.t('messages.export.section.donation_confirmation.received_from',
                  year: 1.year.ago.year))
    end

    def donation_confirmation_received_amount_info
      text(I18n.t('messages.export.section.donation_confirmation.received_amount'))
    end

    def last_year_donation_amount
      currency = letter.invoice.currency

      donation_amount = Donation.new.
                                in_last(1.year).
                                in_layer(letter.group).
                                of_person(@recipient).
                                previous_amount.
                                to_s

      "#{currency} #{donation_amount}"
    end

    def recipient_address
      name = "#{@recipient.first_name}, #{@recipient.last_name} \n"
      name + "#{@recipient.address}, #{@recipient.zip_code} #{@recipient.town}"
    end

    def break_line
      "\n\n"
    end
  end
end
