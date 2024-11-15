# frozen_string_literal: true

#  Copyright (c) 2022-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::LogController do
  let(:top_leader) { people(:top_leader) }
  let(:layer_one_member1) { people(:bottom_member) }
  let(:layer_one_member2) { Fabricate(Group::BottomLayer::Member.to_s, group: group).person }
  let(:layer_two_member) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_two), created_at: 30.days.ago).person }
  let(:group) { groups(:bottom_layer_one) }

  describe "GET index", versioning: true do
    before do
      sign_in(user)

      [layer_one_member1, layer_one_member2, layer_two_member].each do |p|
        Fabricate(:social_account, contactable: p)
        p.update!(town: "Bern", zip_code: "3007")
        Fabricate(:phone_number, contactable: p)
      end
    end

    context "as leader" do
      let(:user) { top_leader }

      it "fetches papertrail versions of group" do
        get :index, params: {group_id: group.id}

        expect(response).to have_http_status(200)

        versions = assigns(:versions)

        # 6 inside before block + 1 layer_one_member2 person create + 1 layer_one_member2 role create
        expect(versions.size).to eq(8)
        expect(versions.map(&:main_id).uniq).to match_array([layer_one_member1.id, layer_one_member2.id])
      end

      it "does not fetch papertrail versions of different group members" do
        get :index, params: {group_id: groups(:bottom_layer_two).id}

        expect(response).to have_http_status(200)

        versions = assigns(:versions)

        # 3 inside before block + 1 layer_two_member person create + 1 layer_two_member role create
        expect(versions.size).to eq(5)
        main_ids = versions.map(&:main_id).uniq
        expect(main_ids).to_not include(layer_one_member1.id)
        expect(main_ids).to_not include(layer_one_member2.id)
        expect(main_ids).to include(layer_two_member.id)
      end
    end

    context "as bottom_member" do
      let(:user) { layer_one_member1 }

      it "is not allowed" do
        expect do
          get :index, params: {group_id: group.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
