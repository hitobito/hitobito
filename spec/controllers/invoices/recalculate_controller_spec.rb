# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Invoices::RecalculateController do
  let(:group) { groups(:bottom_layer_one) }
  before { sign_in(user) }

  describe 'authorization' do
    context 'as person with finance role' do
      let(:user) { Fabricate(Group::BottomLayer::Member.sti_name.to_sym, group: group).person }

      it "may recalculate when person has finance permission on layer group" do
        get :new, xhr: true, params: { group_id: group.id }
        expect(response).to be_successful
      end
    end

    context 'as person without finance role' do
      let(:user) { Fabricate(Group::BottomLayer::BasicPermissionsOnly.sti_name.to_sym, group: group).person }

      it "may not recalculate when person has no finance permission on layer group" do
        get :new, xhr: true, params: { group_id: group.id }
        expect(response).to have_http_status(403)
      end
    end
  end
end

