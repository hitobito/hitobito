#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require_dependency "person/invoices_controller"

describe Person::InvoicesController do
  let(:group) { groups(:top_group) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  context "bottom member" do
    it "may not index top_leader's invoices if we have no finance permission in layer" do
      sign_in(bottom_member)
      expect do
        get :index, params: {group_id: group.id, id: top_leader.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "top leader" do
    before { sign_in(top_leader) }

    it "may index invoices" do
      get :index, params: {group_id: group.id, id: top_leader.id}
      expect(assigns(:invoices)).to have(2).items
    end

    it "may sort invoices" do
      sign_in(top_leader)
      get :index, params: {group_id: group.id, id: top_leader.id, sort: :state, sort_dir: :desc}
      expect(assigns(:invoices)[0].title).to eq "Sent"
    end
  end
end
