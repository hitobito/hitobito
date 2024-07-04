# frozen_string_literal: true

#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_invitations
#
#  id                 :bigint           not null, primary key
#  declined_at        :datetime
#  participation_type :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  event_id           :bigint           not null
#  person_id          :bigint           not null
#
# Indexes
#
#  index_event_invitations_on_event_id                (event_id)
#  index_event_invitations_on_event_id_and_person_id  (event_id,person_id) UNIQUE
#  index_event_invitations_on_person_id               (person_id)
#

class Event::Invitation < ActiveRecord::Base
  self.demodulized_route_keys = true

  belongs_to :event
  belongs_to :person

  validates_by_schema
  validates :person_id,
    uniqueness: {scope: :event_id,
                 message: ->(s, _) {
                            I18n.t("event_invitations.invalid_existing_person",
                              model_name: s.event.model_name.human)
                          }}

  def status
    if related_participation.present?
      :accepted
    elsif declined_at.present?
      :declined
    else
      :open
    end
  end

  def open?
    status == :open
  end

  def related_participation
    Event::Participation.find_by(person_id: person_id,
      event_id: event_id)
  end
end
