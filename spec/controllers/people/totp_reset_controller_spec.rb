# frozen_string_literal: true

#
#  Copyright (c) 2022-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::TotpResetController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_layer) { groups(:bottom_layer_one) }

  describe "POST #create" do
    before do
      sign_in(top_leader)
      [top_leader, bottom_member].each do |person|
        person.update!(two_factor_authentication: :totp,
          two_fa_secret: People::OneTimePassword.generate_secret)
      end
    end

    it "resets own totp and redirects to setup" do
      post :create, params: {group_id: top_group.id, id: top_leader.id}

      top_leader.reload

      expect(response).to redirect_to(new_users_second_factor_path(second_factor: "totp"))
      expect(top_leader.two_factor_authentication).to eq("totp")
      expect(top_leader.two_fa_secret).to eq("")
    end

    it "does not reset totp of other person" do
      expect do
        post :create, params: {group_id: bottom_layer.id, id: bottom_member.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
