# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events
  class GuestLimiter
    attr_reader :free, :limit, :used, :waiting_list

    def initialize(free:, limit:, used:, waiting_list: false)
      @free = free
      @limit = limit
      @used = used
      @waiting_list = waiting_list
    end

    def self.for(event, participant)
      new(
        free: (event.maximum_participants.presence || 1000000) - (event.participant_count.presence || 0),
        limit: event.guest_limit,
        used: event.participations.guests_of(participant).distinct.count,
        waiting_list: event.waiting_list
      )
    end

    def remaining
      personally_available_places = (@limit - @used)
      allowed_places = [@free, personally_available_places].min

      if @waiting_list && allowed_places <= 0
        personally_available_places
      else
        allowed_places
      end
    end
  end
end
