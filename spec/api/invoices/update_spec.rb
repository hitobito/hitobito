# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"

RSpec.describe "invoices#show", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:invoices] do
    let(:payload) {
      {
        data: {
          id: invoice.id.to_s,
          type: "invoices",
          attributes: {
            state: "issued"
          }
        }
      }
    }
    let(:invoice) { invoices(:invoice).tap { |i| i.update(group: groups(:top_layer)) } }

    subject(:make_request) do
      jsonapi_put "/api/invoices/#{invoice.id}", payload
    end

    describe "basic update" do
      it "updates the resource" do
        expect(InvoiceResource).to receive(:find).and_call_original
        expect {
          make_request
          expect(response.status).to eq(200), response.body
        }.to change { invoice.reload.state }.to("issued")
      end
    end
  end
end
