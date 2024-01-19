# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'rails_helper'

RSpec.describe "people#index", type: :request do
  it_behaves_like 'jsonapi authorized requests' do
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/people", params: params
    end

    describe 'basic fetch' do
      it 'works' do
        expect(PersonResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(['people'])
        expect(d.map(&:id)).to match_array(people(:top_leader, :bottom_member).pluck(:id))
      end
    end
  end
end
