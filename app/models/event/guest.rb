#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::Guest < ActiveRecord::Base
  belongs_to :main_applicant, class_name: "Event::Participation"

  def additional_emails
    AdditionalEmail.none
  end

  class << self
    def order_by_name_statement
      Arel.sql(
        <<~SQL.squish
          CASE
            WHEN event_guests.last_name IS NOT NULL AND event_guests.first_name IS NOT NULL THEN event_guests.last_name || ' ' || event_guests.first_name
            WHEN event_guests.last_name IS NOT NULL THEN event_guests.last_name
            WHEN event_guests.first_name IS NOT NULL THEN event_guests.first_name
            WHEN event_guests.nickname IS NOT NULL THEN event_guests.nickname
            ELSE ''
          END
        SQL
      )
    end
  end
end
