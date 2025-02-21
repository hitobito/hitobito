# frozen_string_literal: true

#  Copyright (c) 2022-2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JsonApiController do
  before { sign_in(people(:root)) }

  context "with unhandled exception" do
    controller(JsonApiController) do
      def index = fail "ouch"
    end

    after do
      expect(response.status).to eq 500
      errors = JSON.parse(response.body).deep_symbolize_keys[:errors]
      expect(errors).to have(1).item
      expect(errors.first[:code]).to eq "internal_server_error"
    end

    it "does triggers error trackers" do
      expect(Airbrake).to receive(:notify).with(kind_of(RuntimeError))
      expect(Raven).to receive(:capture_exception).with(kind_of(RuntimeError))
      get :index
    end
  end

  context "with handled exception" do
    controller(JsonApiController) do
      def index = raise ActionController::BadRequest.new
    end

    after do
      expect(response.status).to eq 400
      errors = JSON.parse(response.body).deep_symbolize_keys[:errors]
      expect(errors).to have(1).item
      expect(errors.first[:code]).to eq "bad_request"
    end

    it "does not triggers error trackers" do
      expect(Airbrake).not_to receive(:notify).with(kind_of(RuntimeError))
      expect(Raven).not_to receive(:capture_exception).with(kind_of(RuntimeError))
      get :index
    end
  end
end
