# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class LetterWithInvoice < Invoices

    private

    def pdf_links
      add_item(translate(:letters_with_invoice), export_path(:pdf), item_options)
    end

    def item_options
      super.merge(target: '')
    end

  end
end
