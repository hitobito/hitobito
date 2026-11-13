# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe PeopleManagerResource, type: :resource do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  describe "creating" do
    let(:manager) { Fabricate(:person) }
    let(:payload) do
      {
        data: {
          type: "people_managers",
          attributes: {
            manager_id: manager.id,
            managed_id: bottom_member.id
          }
        }
      }
    end

    let(:instance) { PeopleManagerResource.build(payload) }

    it "works" do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { PeopleManager.count }.by(1)

      people_manager = PeopleManager.last
      expect(people_manager.manager).to eq manager
      expect(people_manager.managed).to eq bottom_member
    end

    context "without manager_id" do
      before { payload[:data][:attributes].delete(:manager_id) }

      it "raises an invalid request error" do
        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end

    context "without managed_id" do
      before { payload[:data][:attributes].delete(:managed_id) }

      it "raises an invalid request error" do
        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end

    context "linking a person to itself" do
      let(:payload) do
        {
          data: {
            type: "people_managers",
            attributes: {
              manager_id: bottom_member.id,
              managed_id: bottom_member.id
            }
          }
        }
      end

      it "fails validation" do
        expect(instance.save).to eq(false)
      end
    end

    context "duplicate relation" do
      before { PeopleManager.create!(manager: manager, managed: bottom_member) }

      it "fails validation" do
        expect(instance.save).to eq(false)
      end
    end

    context "not authorized" do
      let(:ability) { Ability.new(Fabricate(:person)) }

      it "raises AccessDenied" do
        expect {
          expect(instance.save).to eq(false)
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "with the api feature gate disabled" do
      before do
        allow(FeatureGate).to receive(:enabled?).and_call_original
        allow(FeatureGate).to receive(:enabled?).with("people.people_managers.api").and_return(false)
      end

      it "raises AccessDenied" do
        expect {
          expect(instance.save).to eq(false)
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "destroying" do
    let!(:people_manager) { PeopleManager.create!(manager: Fabricate(:person), managed: bottom_member) }
    let(:instance) { PeopleManagerResource.find(id: people_manager.id) }

    it "works" do
      expect {
        expect(instance.destroy).to eq(true)
      }.to change { PeopleManager.count }.by(-1)
    end

    context "not visible" do
      let(:ability) { Ability.new(Fabricate(:person)) }

      it "raises RecordNotFound" do
        expect {
          expect(instance.destroy).to eq(false)
        }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end

    context "leading an event the managed person participates in, with no other relation" do
      let(:person) { Fabricate(:person) }
      let(:event) { events(:top_event) }

      before do
        Fabricate(Event::Role::Leader.name.to_sym,
          participation: Fabricate(:event_participation, event: event, participant: person))
        Fabricate(Event::Role::Participant.name.to_sym,
          participation: Fabricate(:event_participation, event: event, participant: bottom_member))
      end

      it "raises RecordNotFound, same as in the UI leading an event alone grants no write access" do
        expect {
          expect(instance.destroy).to eq(false)
        }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end

    context "with the api feature gate disabled" do
      before do
        allow(FeatureGate).to receive(:enabled?).and_call_original
        allow(FeatureGate).to receive(:enabled?).with("people.people_managers.api").and_return(false)
      end

      it "raises RecordNotFound, as the relation is no longer readable either" do
        expect {
          expect(instance.destroy).to eq(false)
        }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end
  end
end
