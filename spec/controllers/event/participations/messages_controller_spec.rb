# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Participations::MessagesController do
  let(:person) { people(:top_leader) }
  let(:event) { events(:top_course) }
  let(:participation) { event_participations(:top) }
  let(:participant) { participation.participant }

  render_views

  describe "GET index" do
    before do
      sign_in(person)

      # create some messages
      m = Message::SystemMail.create!(event: event, subject: "Application to event", created_at: 1.week.ago)
      m.message_recipients.create!(person: participant, email: participant.email)
      m = Message::SystemMail.create!(event: event, subject: "Event is over", created_at: 1.day.ago)
      m.message_recipients.create!(person: person, email: person.email)
      m = Message::SystemMail.create!(event: events(:top_event), subject: "Other event application")
      m.message_recipients.create!(person: participant, email: participant.email)
    end

    it "fetches messages of participation" do
      get :index, params: {
        group_id: event.groups.first.id,
        event_id: event.id,
        participation_id: participation.id
      }

      messages = assigns(:messages)
      expect(messages.size).to eq(1)
      expect(messages.first.subject).to eq("Application to event")

      expect(response.body).to include("Application to event")
    end
  end
end
