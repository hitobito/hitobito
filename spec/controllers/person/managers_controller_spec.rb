# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth

require "spec_helper"
require_relative "people_managers_shared_examples"

describe Person::ManagersController do
  it_behaves_like "people_managers#create"
  it_behaves_like "people_managers#destroy"

  describe "#create without permission on the managed person" do
    # LocalSecretary has only :layer_read, which makes it the right role for this test:
    # a role without any writing permission, so it has neither :update_email nor
    # :change_managers on the victim, but it is still a regular user with a role.
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

    it "does not allow assigning oneself as manager of an existing person" do
      expect(Ability.new(attacker)).not_to be_able_to(:update_email, victim)

      expect do
        post :create, params: {
          person_id: victim.id,
          people_manager: {manager_id: attacker.id}
        }
      end.not_to change { PeopleManager.count }

      expect(response).to have_http_status(:unprocessable_content)
      expect(victim.reload.managers).not_to include(attacker)
    end
  end
end
