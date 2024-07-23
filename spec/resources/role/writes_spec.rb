# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe RoleResource, type: :resource do
  let(:role) { roles(:top_leader) }
  let(:person) { role.person }
  let(:group) { role.group }
  let(:current_ability) { Ability.new(person) }

  around do |example|
    RSpec::Mocks.with_temporary_scope do
      Graphiti.with_context(double({current_ability: current_ability})) { example.run }
    end
  end

  describe "creating" do
    let(:payload) do
      {
        data: {
          type: "roles",
          attributes: {
            group_id: group.id,
            person_id: person.id,
            type: Group::TopGroup::Member.sti_name,
            label: "test"
          }
        }
      }
    end

    let(:instance) { RoleResource.build(payload) }

    it "works", versioning: true do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { Role.count }.by(1)
        .and change { PaperTrail::Version.count }

      new_role = Role.last
      expect(new_role.person).to eq person
      expect(new_role.group).to eq group
      expect(new_role.type).to eq "Group::TopGroup::Member"
      expect(new_role.label).to eq "test"
    end

    context "other user" do
      let(:current_ability) { Ability.new(people(:bottom_member)) }

      it "cannot create when not able to update person or group" do
        expect {
          expect(instance.save).to eq(true)
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "service token" do
      let(:token) { service_tokens(:permitted_top_layer_token) }
      let(:current_ability) { TokenAbility.new(token) }

      it "can create" do
        expect {
          expect(instance.save).to eq(true)
        }.to change { Role.count }.by(1)
      end

      it "cannot create when token has layer_read only" do
        token.update!(permission: :layer_read)
        expect {
          expect(instance.save).to eq(true)
        }.to raise_error(CanCan::AccessDenied)
      end

      it "cannot create when token has layer_and_below_read only" do
        token.update!(permission: :layer_and_below_read)
        expect {
          expect(instance.save).to eq(true)
        }.to raise_error(CanCan::AccessDenied)
      end

      describe "creating roles in sublayer" do
        before do
          payload[:data][:attributes].deep_merge!(
            group_id: groups(:bottom_layer_one).id,
            type: Group::BottomLayer::Member.sti_name
          )
        end

        it "can create role" do
          expect {
            expect(instance.save).to eq(true)
          }.to change { Role.count }.by(1)
        end

        it "cannot create role with layer_full permission" do
          token.update!(permission: :layer_full)

          expect {
            expect(instance.save).to eq(true)
          }.to raise_error(CanCan::AccessDenied)
        end
      end
    end
  end

  describe "updating" do
    let(:payload) do
      {
        id: role.id.to_s,
        data: {
          id: role.id.to_s,
          type: "roles"
        }
      }
    end

    let(:instance) { RoleResource.find(payload) }

    it "may update label" do
      payload[:data][:attributes] = {label: "some text"}
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { role.reload.label }.to("some text")
    end

    context "other user" do
      let(:current_ability) { Ability.new(people(:bottom_member)) }

      it "cannot update non writable person" do
        expect {
          expect(instance.update_attributes).to eq(true)
        }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end

    describe "readonly attributes" do
      it "rejects updates to type" do
        payload[:data][:attributes] = {type: Group::TopGroup::Member.sti_name}
        expect {
          instance.update_attributes
        }.to raise_error(Graphiti::Errors::InvalidRequest)
      end

      it "rejects changed to group_id" do
        payload[:data][:attributes] = {group_id: groups(:bottom_layer_one).id}
        expect {
          instance.update_attributes
        }.to raise_error(Graphiti::Errors::InvalidRequest)
      end

      it "rejects changed to person_id" do
        payload[:data][:attributes] = {person_id: people(:bottom_member).id}
        expect {
          instance.update_attributes
        }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end
  end

  describe "destroying" do
    let(:role) { Fabricate(Group::TopGroup::Member.sti_name, group: groups(:top_group), person: people(:top_leader)) }

    let(:instance) { RoleResource.find(id: role.id) }

    it "works" do
      expect {
        expect(instance.destroy).to be_truthy
      }.to change { Role.count }.by(-1)
    end

    context "other user" do
      let(:current_ability) { Ability.new(people(:bottom_member)) }

      it "cannot destroy non writable person" do
        expect {
          expect(instance.destroy).to eq(true)
        }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end
  end

  describe "sideposting" do
    let(:payload) do
      {
        id: role.id.to_s,
        data: {
          id: role.id.to_s,
          type: "roles"
        }
      }
    end

    let(:instance) { RoleResource.find(payload) }

    it "cannot update group" do
      payload.deep_merge!(
        data: {
          relationships: {
            group: {
              data: [
                {
                  id: group.id,
                  type: "groups",
                  method: "update"
                }
              ]
            }
          }
        },
        included: [{
          id: group.id,
          type: "groups",
          attributes: {
            name: "new name"
          }
        }]
      )
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to not_change { group.reload.name }
        .and raise_error(Graphiti::Errors::InvalidRequest)
    end

    it "cannot update person" do
      payload.deep_merge!(
        data: {
          relationships: {
            person: {
              data: [
                {
                  id: person.id,
                  type: "people",
                  method: "update"
                }
              ]
            }
          }
        },
        included: [{
          id: person.id,
          type: "people",
          attributes: {
            first_name: "new name"
          }
        }]
      )
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to not_change { person.reload.first_name }
        .and raise_error(Graphiti::Errors::InvalidRequest)
    end
  end
end
