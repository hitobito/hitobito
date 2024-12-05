# frozen_string_literal: true

#  Copyright (c) 2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::StatisticsController do
  let(:user) { people(:top_leader) }
  let(:group) { groups(:bottom_layer_one) }

  describe "GET index" do
    before { sign_in(user) }

    it "shows list of years" do
      get :index, params: {group_id: group.id}

      expect(response).to have_http_status(200)

      age_groups = assigns(:age_groups)
      expect(age_groups.size).to eq(1)
    end
  end
end
