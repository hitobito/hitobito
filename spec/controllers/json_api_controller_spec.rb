# frozen_string_literal: true

#  Copyright (c) 2022-2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JsonApiController do
  controller(JsonApiController) do
    def index
      fail "ouch"
    end
  end

  context "with logged in user" do
    before do
      sign_in(people(:root))
    end

    after do
      expect(response.status).to eq 500
      errors = JSON.parse(response.body).deep_symbolize_keys[:errors]
      expect(errors).to have(1).item
      expect(errors.first[:code]).to eq "internal_server_error"
    end

    context "local environment" do
      it "does not trigger Airbrake" do
        expect(Airbrake).not_to receive(:notify)
        get :index
      end
    end

    context "production" do
      it "does trigger Airbrake" do
        expect(Rails.env).to receive(:production?).and_return(true)
        expect(Airbrake).to receive(:notify).with(kind_of(RuntimeError))
        get :index
      end
    end
  end
end