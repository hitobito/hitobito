# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'rails_helper'

RSpec.describe "groups#show", type: :request do
  it_behaves_like 'jsonapi authorized requests' do
    let(:params) { {} }
    let(:group) { groups(:top_group) }

    subject(:make_request) do
      jsonapi_get "/api/groups/#{group.id}", params: params
    end

    describe 'basic fetch' do
      it 'works' do
        expect(GroupResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq('groups')
        expect(d.id).to eq(group.id)
      end
    end
  end
end
