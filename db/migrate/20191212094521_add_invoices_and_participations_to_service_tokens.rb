#  Copyright (c) 2019, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddInvoicesAndParticipationsToServiceTokens < ActiveRecord::Migration
  def change
    add_column(:service_tokens, :invoices, :boolean, default: false, null: false)
    add_column(:service_tokens, :event_participations, :boolean, default: false, null: false)
  end
end
