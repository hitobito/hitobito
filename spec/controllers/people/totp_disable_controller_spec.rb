# frozen_string_literal: true

#
#  Copyright (c) 2022-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::TotpDisableController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:bottom_layer) { groups(:bottom_layer_one) }

  describe "POST #create" do
    before do
      sign_in(top_leader)
      bottom_member.two_factor_authentication = :totp
      bottom_member.two_fa_secret = People::OneTimePassword.generate_secret
      bottom_member.save!
    end

    it "disables totp of bottom_member" do
      post :create, params: {group_id: bottom_layer.id, id: bottom_member.id}

      bottom_member.reload

      expect(response).to redirect_to(group_person_path(bottom_layer, bottom_member))
      expect(flash[:notice]).to include("Zwei-Faktor-Authentifizierung erfolgreich deaktiviert")
      expect(bottom_member.two_factor_authentication).to be_nil
      expect(bottom_member.two_fa_secret).to eq("")
    end

    it "disables totp of bottom_member when enforced" do
      allow_any_instance_of(bottom_member.roles.first.class)
        .to receive(:two_factor_authentication_enforced)
        .and_return(true)

      post :create, params: {group_id: bottom_layer.id, id: bottom_member.id}

      expect(bottom_member.reload.two_factor_authentication).to be_nil
    end

    it "does not disable own totp when enforced" do
      allow_any_instance_of(Group::TopGroup::Leader)
        .to receive(:two_factor_authentication_enforced)
        .and_return(true)

      expect do
        post :create, params: {group_id: groups(:top_group).id, id: top_leader.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
