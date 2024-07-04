# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe "event_kinds#index", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/event_kinds", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(Event::KindResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["event_kinds"])
        expect(d.map(&:id)).to match_array(Event::Kind.where(deleted_at: nil).pluck(:id))
      end
    end
  end
end
