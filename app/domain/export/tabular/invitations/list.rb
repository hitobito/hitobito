# frozen_string_literal: true

#  Copyright (c) 2014-2023, Carbon. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Invitations
  class List < Export::Tabular::Base
    self.model_class = Event::Invitation
    self.row_class = Export::Tabular::Invitations::Row

    def attributes
      [:person, :mail, :participation_type, :status, :declined_at, :created_at]
    end
  end
end
