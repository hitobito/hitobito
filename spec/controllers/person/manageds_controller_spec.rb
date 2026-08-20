# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "people_managers_shared_examples"

describe Person::ManagedsController do
  it_behaves_like "people_managers#create"
  it_behaves_like "people_managers#destroy"

  describe "#create with self_service_managed_creation enabled" do
    # LocalSecretary has only :layer_read, which makes it the right role for this test:
    # a role without any writing permission, so it has neither :update_email nor
    # :change_managers on the victim. It is also the role used for the self service
    # scenario in spec/features/people_managers_spec.rb.
    let(:attacker) do
      Fabricate(Group::TopGroup::LocalSecretary.sti_name, group: groups(:top_group)).person
    end
    let(:victim) { people(:top_leader) }

    before do
      allow(FeatureGate).to receive(:enabled?).and_call_original
      allow(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(true)
      allow(FeatureGate).to receive(:enabled?)
        .with("people.people_managers.self_service_managed_creation").and_return(true)

      sign_in(attacker)
    end

    it "allows creating a new managed person" do
      expect do
        post :create, params: {
          person_id: attacker.id,
          people_manager: {managed_attributes: {first_name: "Test", last_name: "Kind"}}
        }
      end.to change { attacker.reload.manageds.count }.by(1)

      expect(response).to redirect_to(person_manageds_path(attacker))
    end

    it "does not allow assigning an existing person without permission on that person" do
      expect(Ability.new(attacker)).not_to be_able_to(:update_email, victim)

      expect do
        post :create, params: {
          person_id: attacker.id,
          people_manager: {managed_id: victim.id}
        }
      end.not_to change { PeopleManager.count }

      expect(response).to have_http_status(:unprocessable_content)
      expect(victim.reload.managers).not_to include(attacker)
    end
  end
end
