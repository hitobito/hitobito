# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Returns all people whose details are readable.
class PersonDetailsReadables < PersonReadables
  private

  def contact_data_visible?
    false
  end

  def group_read_contact_data_group_ids
    []
  end
end
