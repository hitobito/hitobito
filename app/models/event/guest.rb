#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::Guest < ActiveRecord::Base
  belongs_to :main_applicant, class_name: "Event::Participation"

  delegate :to_s, :gender_label, to: :to_person

  GUEST_SPECIFIC_ATTRIBUTES = [:id, :phone_number, :main_applicant_id]

  def additional_emails
    AdditionalEmail.none
  end

  def to_person
    Person.new(person_attributes).tap do |person|
      if phone_number?
        person.phone_numbers.build(number: phone_number)
      end
    end
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

  private

  def person_attributes
    attributes.reject { |attr| GUEST_SPECIFIC_ATTRIBUTES.include?(attr.to_sym) }
  end
end
