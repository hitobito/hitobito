# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceIndex; end 

ThinkingSphinx::Index.define_partial :invoice do
  indexes title, sortable: true
  indexes reference, sortable: true
  indexes sequence_number, sortable: true

  has group_id, type: :integer
end
