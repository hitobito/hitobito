# encoding: utf-8

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe HealthzController do
  describe "GET show" do
    let(:json) { JSON.parse(response.body) }

    context "when things are running smoothly" do
      it "has HTTP status 200" do
        get :show

        expect(response.status).to eq(200)

        expect(json).to eq("app_status" => {"code" => "ok", "details" => {"store_ok?" => true}})
      end
    end

    context "when the status is unhealthy" do
      it "has HTTP status 503" do
        expect_any_instance_of(AppStatus::Store).to receive(:store_ok?).and_return(false)

        get :show

        expect(response.status).to eq(503)

        expect(json).to eq("app_status" => {"code" => "service_unavailable", "details" => {"store_ok?" => false}})
      end
    end
  end
end
