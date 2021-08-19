# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Messages::LettersWithInvoice
  class Row < Export::Tabular::Row
    self.dynamic_attributes = List::PERSON_ATTRS.each_with_object({}) do |attr, dynamic_attributes|
      dynamic_attributes[Regexp.new("^(#{attr})")] = :person_attribute
    end

    def person_attribute(attr)
      entry.recipient.try(attr)
    end
  end
end
