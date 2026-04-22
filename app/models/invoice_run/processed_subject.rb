# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceRun::ProcessedSubject < ActiveRecord::Base
  self.table_name = "invoice_run_processed_subjects"

  belongs_to :item, class_name: "InvoiceItem"
end
