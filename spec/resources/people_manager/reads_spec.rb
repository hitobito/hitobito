# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe PeopleManagerResource do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let!(:people_manager) { PeopleManager.create!(manager: top_leader, managed: bottom_member) }

  describe "serialization" do
    context "with permission on the managed person" do
      it "works" do
        render
        data = jsonapi_data[0]
        expect(data.id).to eq(people_manager.id)
        expect(data.jsonapi_type).to eq("people_managers")
        expect(data.manager_id).to eq(top_leader.id)
        expect(data.managed_id).to eq(bottom_member.id)
      end
    end

    context "without permission on the managed person" do
      let(:ability) { Ability.new(Fabricate(:person)) }

      it "does not expose data" do
        render
        expect(jsonapi_data).to eq([])
      end
    end

    context "as leader of an event the managed person participates in, with no other relation" do
      let(:person) { Fabricate(:person) }
      let(:event) { events(:top_event) }

      before do
        Fabricate(Event::Role::Leader.name.to_sym,
          participation: Fabricate(:event_participation, event: event, participant: person))
        Fabricate(Event::Role::Participant.name.to_sym,
          participation: Fabricate(:event_participation, event: event, participant: bottom_member))
      end

      it "does not expose data, as leading an event is not sufficient on its own, same as in the UI" do
        render
        expect(jsonapi_data).to eq([])
      end
    end

    context "with the api feature gate disabled" do
      before do
        allow(FeatureGate).to receive(:enabled?).and_call_original
        allow(FeatureGate).to receive(:enabled?).with("people.people_managers.api").and_return(false)
      end

      it "does not expose data" do
        render
        expect(jsonapi_data).to eq([])
      end
    end
  end

  describe "including" do
    it "may include manager" do
      params[:include] = "manager"
      render
      manager = d[0].sideload(:manager)
      expect(manager.id).to eq top_leader.id
    end

    it "may include managed" do
      params[:include] = "managed"
      render
      managed = d[0].sideload(:managed)
      expect(managed.id).to eq bottom_member.id
    end

    context "when the manager is not independently visible to the viewer" do
      let(:unrelated_manager) { Fabricate(:person) }
      let!(:people_manager) { PeopleManager.create!(manager: unrelated_manager, managed: bottom_member) }

      it "does not expose the manager, even though the relation itself is readable" do
        params[:include] = "manager"
        render
        expect(jsonapi_data).to have(1).item
        expect(d[0].sideload(:manager)).to be_nil
      end
    end
  end
end
