# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Invoices
  class Row < Export::Tabular::Row

    def initialize(entry, format = nil)
      @entry = InvoiceDecorator.decorate(entry)
      @format = format
    end

    def state
      entry.state_label
    end

  end
end
