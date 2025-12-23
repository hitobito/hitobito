# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# This module is used to preloading the polymorphic association `recipient` on `Invoice`.
module Invoice::PreloadRecipients
  def exec_queries
    super.tap do |records|
      ActiveRecord::Associations::Preloader.new(records: records, associations: [:recipient]).call
    end
  end
end
