# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MountedAttributeAttached < MountedAttribute
  self.table_name = 'mounted_attributes'

  has_one_attached :value

  def casted_value
    value
  end
end
