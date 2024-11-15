# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe "events#index", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/events", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(EventResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(%w[events courses])
        expect(d.map(&:id)).to match_array(Event.pluck(:id))
      end
    end

    context "with kind_category_id filter" do
      let(:kind_category) { Event::KindCategory.create!(label: "Event") }

      before { Event.first.kind.update!(kind_category: kind_category) }

      it "only fetches events with specified kind_category_id" do
        expect(EventResource).to receive(:all).and_call_original
        jsonapi_get "/api/events", params: params.merge(filter: {kind_category_id: kind_category.id})
        expect(response.status).to eq(200), response.body
        expect(d.map(&:id)).to match_array([Event.first.id])
      end
    end
  end
end
