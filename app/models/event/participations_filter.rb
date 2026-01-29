#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationsFilter < ActiveRecord::Base
  belongs_to :event

  def to_params
    {filters: {participant_type: participant_type}}
  end
end
