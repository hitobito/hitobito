# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'rails_helper'

RSpec.describe "invoices#index", type: :request do
  it_behaves_like 'jsonapi authorized requests' do
    let(:token) { service_tokens(:permitted_bottom_layer_token).token }
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/invoices", params: params
    end

    describe 'basic fetch' do
      it 'works' do
        expect(InvoiceResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(['invoices'])
      end
    end
  end
end
