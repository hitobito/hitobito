# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Events::Filter::List < Filter::List
  self.item_class = Event
  self.filter_chain_class = Events::Filter::Chain

  def entries
    super.preload(:groups, :events_groups, :translations, :dates)
  end

  private

  def accessible_scope
    Event.accessible_by(EventReadables.new(user))
  end
end
