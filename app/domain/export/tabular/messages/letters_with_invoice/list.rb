# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Messages::LettersWithInvoice
  class List < Export::Tabular::Base
    INCLUDED_ATTRS = %w(esr_number recipient_email recipient_address reference total).freeze
    PERSON_ATTRS = %w(id first_name last_name company_name company email
                      address zip_code town country gender birthday
                      salutation title correspondence_language household_key).freeze

    self.model_class = ::Invoice
    self.row_class = Export::Tabular::Messages::LettersWithInvoice::Row

    def build_attribute_labels
      invoice_attribute_labels.merge(person_attribute_labels)
    end

    def invoice_attribute_labels
      INCLUDED_ATTRS.collect(&:to_sym).index_with { |attr| attribute_label(attr) }
    end

    def person_attribute_labels
      PERSON_ATTRS.collect(&:to_sym).index_with { |attr| person_attribute(attr) }
    end

    def person_attribute(attr)
      Person.human_attribute_name(attr)
    end
  end
end
