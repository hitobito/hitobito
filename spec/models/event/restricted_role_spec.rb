# frozen_string_literal: true

#  Copyright (c) 2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::RestrictedRole do
  let(:person) { people(:bottom_member) }

  before do
    stub_const("Event::Restricted", Class.new(Event) do
      include Event::RestrictedRole

      restricted_role :cook, Event::Role::Cook
    end)
    allow(Group::TopLayer).to receive(:event_types).and_return([Event::Restricted])
  end

  def build_event(**attrs)
    Event::Restricted.new(name: "Restricted", groups: [groups(:top_layer)], **attrs)
  end

  it "creates participation with restricted role for event" do
    event = build_event(dates: [Event::Date.new(start_at: Time.zone.local(2012, 5, 11))])
    event.cook_id = person.id

    event.save!

    expect(event.reload.cook).to eq person
    expect(event.participations.map(&:participant)).to eq [person]
  end

  it "does not create participation with restricted role for template" do
    template = build_event(template: true)
    template.cook_id = person.id

    expect { template.save! }.not_to change { Event::Participation.count }
  end
end
