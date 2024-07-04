# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe HouseholdsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }

  let(:group) { top_group }
  let(:person) { top_leader }
  let(:params) { {group_id: group.id, person_id: person.id} }

  before { sign_in(person) }

  describe "unauthorized" do
    before { sign_in(bottom_member) }

    it "may not edit" do
      expect { get :edit, params: params }.to raise_error(CanCan::AccessDenied)
    end

    it "may not update" do
      expect { put :update, params: params }.to raise_error(CanCan::AccessDenied)
    end

    it "may not destroy" do
      expect { delete :destroy, params: params }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "#edit" do
    let(:household) { assigns(:entry) }

    context "without member_ids" do
      it "holds person" do
        get :edit, params: params
        expect(household.people).to eq [person]
      end

      it "holds people from persisted household" do
        Person.where(id: [person.id, bottom_member.id]).update_all(household_key: 123)
        get :edit, params: params
        expect(household.people).to match_array [person, bottom_member]
      end

      it "does not validate household" do
        get :edit, params: params
        expect(household.warnings).to be_empty
      end
    end

    context "with member_ids" do
      it "holds only people passed as member_ids" do
        get :edit, params: params.merge(member_ids: [bottom_member.id])
        expect(household.people).to eq [bottom_member]
      end

      it "ignores persisted household" do
        Person.where(id: [person.id, bottom_member.id]).update_all(household_key: 123)
        get :edit, params: params.merge(member_ids: [bottom_member.id])
        expect(household.people).to eq [bottom_member]
      end

      describe "warnings and errors" do
        let(:household) { assigns(:entry) }
        let(:error) { household.errors.first.message }
        let(:warning) { household.warnings.first.message }

        it "warns when saving with single person would dissolve houseold" do
          get :edit, params: params.merge(member_ids: [top_leader.id])
          expect(warning).to eq "Der Haushalt wird aufgelöst da weniger als 2 Personen " \
                                "vorhanden sind."
        end

        it "warns if address would change" do
          person.update!(street: "Superstreet", housenumber: 123, zip_code: 4567)
          bottom_member.update!(town: "Motown")
          get :edit, params: params.merge(member_ids: [person.id, bottom_member.id])
          expect(warning).to eq "Die Adresse 'Superstreet 123, 4567 Supertown' wird für " \
                                "alle Personen in diesem Haushalt übernommen."
        end

        it "shows error when person is already assigned to a different household" do
          Person.where(id: [bottom_member.id]).update_all(household_key: 123)
          get :edit, params: params.merge(member_ids: [top_leader.id, bottom_member.id])
          expect(error).to eq "Bottom Member ist bereits Mitglied eines anderen Haushalts."
        end
      end

      describe "non writable person" do
        let(:group) { groups(:bottom_layer_one) }
        let(:bottom_leader) { Fabricate(Group::BottomLayer::Leader.sti_name, group: group).person }
        let(:person) { bottom_leader }

        it "is ignored if any address attr differ" do
          get :edit, params: params.merge(member_ids: [bottom_leader.id, top_leader.id])
          expect(household.people).to match_array([bottom_leader])
        end

        it "is accepted if all address attrs are blank" do
          top_leader.update!(town: nil)
          get :edit, params: params.merge(member_ids: [bottom_leader.id, top_leader.id])
          expect(household.people).to match_array([bottom_leader, top_leader])
        end

        it "is accepted if all address attrs are identical" do
          bottom_leader.update!(town: "Supertown")
          get :edit, params: params.merge(member_ids: [bottom_leader.id, top_leader.id])
          expect(household.people).to match_array([bottom_leader, top_leader])
        end
      end
    end
  end

  describe "#update" do
    let(:household) { Household.new(person) }
    let(:top_member) { Fabricate(Group::TopGroup::Member.sti_name, group: group).person }

    it "adds single member" do
      expect do
        put :update, params: params.merge(member_ids: [person.id, bottom_member.id])
      end.to change { household.reload.members.count }.by(1)
    end

    it "removes single member" do
      household.add(bottom_member)
      expect(household.save).to eq true
      expect do
        put :update, params: params.merge(member_ids: [person.id])
        expect(flash[:notice]).to eq "Haushalt wurde erfolgreich gelöscht."
        expect(response).to redirect_to([group, person])
      end.to change { household.reload.members.count }.by(-1)
    end

    it "removes main person" do
      household.add(top_member)
      household.add(bottom_member)
      expect(household.save).to eq true
      expect do
        put :update, params: params.merge(member_ids: [top_member.id, bottom_member.id])
        expect(flash[:notice]).to eq "Haushalt wurde erfolgreich aktualisiert."
        expect(response).to redirect_to([group, person])
      end.to change { Household.new(bottom_member).reload.members.count }.by(-1)
      expect(person.reload.household_key).to be_nil
    end

    describe "non writable person" do
      let(:group) { groups(:bottom_layer_one) }
      let(:bottom_leader) { Fabricate(Group::BottomLayer::Leader.sti_name, group: group).person }
      let(:person) { bottom_leader }

      it "is ignored if any address attr differ" do
        expect do
          put :update, params: params.merge(member_ids: [bottom_leader.id, top_leader.id])
        end.not_to(change { household.reload.members.count })
      end

      it "is accepted if all address attrs are blank" do
        top_leader.update!(town: nil)
        expect do
          put :update, params: params.merge(member_ids: [bottom_leader.id, top_leader.id])
        end.to change { household.reload.members.count }.by(1)
      end

      it "is accepted if all address attrs are identical" do
        bottom_leader.update!(town: "Supertown")
        expect do
          put :update, params: params.merge(member_ids: [bottom_leader.id, top_leader.id])
        end.to change { household.reload.members.count }.by(1)
      end
    end
  end

  describe "#destroy" do
    it "redirects to person and updates flash on success" do
      delete :destroy, params: params
      expect(person.reload.household_key).to be_nil
      expect(bottom_member.reload.household_key).to be_nil
      expect(flash[:notice]).to eq "Haushalt wurde erfolgreich gelöscht."
      expect(response).to redirect_to([group, person])
    end

    it "redirects to person and updates flash on error" do
      person.household.add(bottom_member)
      expect(person.household.save).to eq true
      allow_any_instance_of(Household).to receive(:valid?).with(:destroy) do |obj|
        obj.errors.add(:base, "may not be destroyed")
        false
      end
      delete :destroy, params: params
      expect(person.reload.household_key).to be_present
      expect(bottom_member.reload.household_key).to be_present
      expect(flash[:alert]).to eq ["may not be destroyed"]
      expect(response).to redirect_to([group, person])
    end
  end
end
