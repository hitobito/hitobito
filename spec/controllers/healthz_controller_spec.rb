# frozen_string_literal: true

#  Copyright (c) 2017-2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe HealthzController do
  describe "GET show with token" do
    let(:json) { JSON.parse(response.body) }
    let(:token) { AppStatus.auth_token }

    context "when true mail can verify valid e-mail address" do
      it "has HTTP status 200" do
        expect(Truemail).to receive(:valid?).with("pushkar@vibha.org").and_return(true)

        get :show, params: {token: token}

        expect(response.status).to eq(200)

        expect(json).to eq("app_status" =>
                           {"code" => "ok",
                            "details" => {"truemail_working" => true,
                                          "validated_email" => "pushkar@vibha.org"}})
      end
    end

    context "when true mail cannot verify valid e-mail address" do
      it "has HTTP status 503" do
        expect(Truemail).to receive(:valid?).with("pushkar@vibha.org").and_return(false)

        get :show, params: {token: token}

        expect(response.status).to eq(503)

        expect(json).to eq("app_status" =>
                           {"code" => "service_unavailable",
                            "details" => {"truemail_working" => false,
                                          "validated_email" => "pushkar@vibha.org"}})
      end
    end
  end

  describe "GET show without token" do
    let(:json) { JSON.parse(response.body) }

    context "when true mail can verify valid e-mail address" do
      it "has HTTP status 200" do
        expect(Truemail).to receive(:valid?).with("pushkar@vibha.org").and_return(true)

        get :show

        expect(response.status).to eq(200)

        expect(json).to eq("app_status" =>
                           {"code" => "ok",
                            "details" => {"truemail_working" => true}})
      end
    end

    context "when true mail cannot verify valid e-mail address" do
      it "has HTTP status 503" do
        expect(Truemail).to receive(:valid?).with("pushkar@vibha.org").and_return(false)

        get :show

        expect(response.status).to eq(503)

        expect(json).to eq("app_status" =>
                           {"code" => "service_unavailable",
                            "details" => {"truemail_working" => false}})
      end
    end
  end
end
