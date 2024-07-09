# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"

RSpec.describe "invoices#show", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:token) { service_tokens(:permitted_bottom_layer_token).token }
    let(:params) { {} }
    let(:invoice) { invoices(:invoice) }

    subject(:make_request) do
      jsonapi_get "/api/invoices/#{invoice.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(InvoiceResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.jsonapi_type).to eq("invoices")
        expect(d.id).to eq(invoice.id)
      end
    end
  end
end
