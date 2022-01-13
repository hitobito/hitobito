# frozen_string_literal: true
#
#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe People::TotpResetController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:bottom_layer) { groups(:bottom_layer_one) }

  describe 'POST #create' do
    before do
      sign_in(top_leader)
      bottom_member.two_factor_authentication = :totp
      bottom_member.two_factor_authentication_secret = People::OneTimePassword.generate_secret
      bottom_member.save!
    end

    it 'resets totp of bottom_member' do
      post :create, params: { group_id: bottom_layer.id, id: bottom_member.id }

      bottom_member.reload

      expect(response).to redirect_to(group_person_path(bottom_layer, bottom_member))
      expect(flash[:notice]).to include('Zwei Faktor Authentifizierung erfolgreich zurückgesetzt')
      expect(bottom_member.two_factor_authentication).to eq('totp')
      expect(bottom_member.two_factor_authentication_secret).to be_nil
    end
  end
end
