# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonDuplicatesController < ListController
  self.nesting = Group

  decorates :person_duplicates, :group

  private

  alias group parent

  def authorize_class
    authorize!(:manage_person_duplicates, group)
  end

  def list_entries
    super.list
  end

end
