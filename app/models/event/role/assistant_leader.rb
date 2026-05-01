#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# Hilfsleiter
class Event::Role::AssistantLeader < Event::Role
  self.permissions = [:event_full, :participations_full]

  self.kind = :leader
end
