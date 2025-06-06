# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RenameInvoiceListsRecipientIdsToRecipients < ActiveRecord::Migration[7.1]
  def change
    rename_column(:invoice_lists, :recipient_ids, :receivers)
  end
end
