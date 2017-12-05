# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceConfigsController < CrudController

  self.nesting = Group
  self.permitted_attrs = [:payment_information, :address, :iban, :account_number]

  private

  def build_entry
    parent.invoice_config
  end

  def find_entry
    parent.invoice_config
  end

  def path_args(_)
    [parent, :invoice_config]
  end

end
