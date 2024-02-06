# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::PaymentsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:ids]

  def initialize(format, user_id, ids, options)
    super(format, user_id, options)
    @ids = ids
    @exporter = Export::Tabular::Payments::List
  end

  private

  def entries
    Payment.where(id: @ids)
  end

end
