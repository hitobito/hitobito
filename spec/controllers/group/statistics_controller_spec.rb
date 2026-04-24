# frozen_string_literal: true

#  Copyright (c) 2024-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::StatisticsController do
  let(:user) { people(:top_leader) }
  let(:group) { groups(:bottom_layer_one) }

  before { sign_in(user) }

  describe "GET index" do
    it "redirects to first available statistic" do
      get :index, params: {group_id: group.id}

      expect(response).to redirect_to group_statistic_path(group, :people)
    end

    context "when no statistics available" do
      before do
        allow(Group::Statistics::Registry).to receive(:available_for).and_return([])
      end

      it "redirects to group with alert" do
        get :index, params: {group_id: group.id}

        expect(response).to redirect_to group_path(group)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "GET show" do
    it "renders the statistic partial" do
      get :show, params: {group_id: group.id, key: :people}

      expect(response).to have_http_status(200)
      expect(assigns(:statistic)).to be_a(Group::Statistics::Demographic)
    end

    it "redirects with alert for unknown key" do
      get :show, params: {group_id: group.id, key: :unknown}

      expect(response).to redirect_to group_path(group)
      expect(flash[:alert]).to be_present
    end

    context "when statistic not available for group" do
      let(:non_layer_group) { groups(:bottom_group_one_one) }

      it "redirects with alert" do
        get :show, params: {group_id: non_layer_group.id, key: :people}

        expect(response).to redirect_to group_path(non_layer_group)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
