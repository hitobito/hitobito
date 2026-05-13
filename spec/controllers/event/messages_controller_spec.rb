# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::MessagesController do
  let(:person) { people(:top_leader) }
  let(:event) { events(:top_course) }

  render_views

  describe "GET index" do
    before do
      sign_in(person)

      # create some messages
      m = Message::SystemMail.create!(event: event, subject: "Application to event", created_at: 1.week.ago)
      m.message_recipients.create!(person: people(:bottom_member), email: people(:bottom_member).email)
      m = Message::SystemMail.create!(event: event, subject: "Event is over", created_at: 1.day.ago)
      m.message_recipients.create!(person: person, email: person.email)
      m = Message::SystemMail.create!(event: events(:top_event), subject: "Other event")
      m.message_recipients.create!(person: person, email: person.email)
    end

    it "fetches messages of event" do
      get :index, params: {group_id: event.groups.first.id, event_id: event.id}

      messages = assigns(:messages)
      expect(messages.size).to eq(2)
      expect(messages.first.subject).to eq("Event is over")
      expect(messages.second.subject).to eq("Application to event")

      expect(response.body).to include(people(:bottom_member).to_s)
      expect(response.body).to include(person.to_s)
    end
  end
end
