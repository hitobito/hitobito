#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PersonDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers

  let(:person) { people(:top_leader) }

  subject { PersonDecorator.new(person) }

  its(:full_label) { is_expected.to == "Top Leader, Supertown" }
  its(:address_name) { is_expected.to == "<strong>Top Leader</strong>" }

  context "with town and birthday" do
    let(:person) do
      Fabricate(:person, first_name: "Fra",
                         last_name: "Stuck",
                         nickname: "Schu",
                         company_name: "Coorp",
                         birthday: "3.8.76",
                         town: "City")
    end

    its(:full_label) { is_expected.to == "Fra Stuck / Schu, City (1976)" }
    its(:address_name) { is_expected.to == "Coorp<br /><strong>Fra Stuck / Schu</strong>" }
    its(:additional_name) { is_expected.to == "Coorp" }
  end

  context "as company" do
    let(:person) do
      Fabricate(:person, first_name: "Fra",
                         last_name: "Stuck",
                         nickname: "Schu",
                         company_name: "Coorp",
                         birthday: "3.8.76",
                         town: "City",
                         company: true)
    end

    its(:full_label) { is_expected.to == "Coorp, City (Fra Stuck)" }
    its(:address_name) { is_expected.to == "<strong>Coorp</strong><br />Fra Stuck" }
    its(:additional_name) { is_expected.to == "Fra Stuck" }
  end

  context "roles grouped" do
    let(:roles_grouped) { PersonDecorator.new(person).roles_grouped }

    before do
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: person)
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: person)
    end

    specify do
      expect(roles_grouped.size).to eq(2)
      expect(roles_grouped[groups(:top_group)].size).to eq(2)
      expect(roles_grouped[groups(:bottom_layer_one)].size).to eq(1)
    end
  end

  context "participations" do
    it "pending_applications returns participations that are not active" do
      dates = [Fabricate(:event_date, start_at: 10.days.from_now.to_date, finish_at: 18.days.from_now.to_date)]
      course = Fabricate(:course, groups: [groups(:top_layer)], dates: dates)
      participation = Fabricate(:event_participation, event: course, person: person)
      application = Fabricate(:event_application, priority_1: course, participation: participation)

      expect(subject.pending_applications).to eq [application]
    end

    it "pending_applications does not return past events" do
      dates = [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 8.days.ago)]
      course = Fabricate(:course, groups: [groups(:top_layer)], dates: dates)
      participation = Fabricate(:event_participation, event: course, person: person, active: true)
      Fabricate(:event_application, priority_1: course, participation: participation)

      expect(subject.pending_applications).to be_empty
    end

    it "upcoming_events returns participations that are active" do
      dates = [Fabricate(:event_date, start_at: 2.days.from_now, finish_at: 5.days.from_now)]
      course = Fabricate(:course, groups: [groups(:top_layer)], dates: dates)
      Fabricate(:event_participation, event: course, person: person, active: true)

      expect(subject.upcoming_events).to eq [course]
    end

    it "upcoming_events does not return past events" do
      dates = [Fabricate(:event_date, start_at: 10.days.ago, finish_at: 8.days.ago)]
      course = Fabricate(:course, groups: [groups(:top_layer)], dates: dates)
      Fabricate(:event_participation, event: course, person: person, active: true)

      expect(subject.upcoming_events).to be_empty
    end
  end

  context "layer group" do
    let(:label) { PersonDecorator.new(person).layer_group_label }

    it "creates link for group layer" do
      expect(label).to match /Top/
      expect(label).to match /#{groups(:top_layer).id}/
    end

    it "empty string if no group layer" do
      person.update!(primary_group: nil)
      expect(label).to be nil
    end
  end
end
