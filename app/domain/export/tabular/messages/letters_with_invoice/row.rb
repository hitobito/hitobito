# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Messages::LettersWithInvoice
  class Row < Export::Tabular::Row
    person_entry_attrs = List::PERSON_ATTRS - ['salutation']

    self.dynamic_attributes = person_entry_attrs.each_with_object({}) do |attr, dynamic_attributes|
      dynamic_attributes[Regexp.new("^(#{attr})")] = :person_attribute
    end

    private

    def person_attribute(attr)
      entry.recipient.try(attr)
    end

    def salutation
      Salutation.new(entry.recipient, message&.salutation).value
    end

    def message
      Message::LetterWithInvoice.find_by(invoice_list: entry.invoice_list)
    end
  end
end
