# frozen_string_literal: true

#  Copyright (c) 2017-2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe HealthzController do
  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original

    stub_file_read("/sys/fs/cgroup/memory.max", "2000000")
    stub_file_read("/sys/fs/cgroup/memory.current", "1500000")
    stub_file_read("/sys/fs/cgroup/memory.stat", "inactive_file 100000")
  end

  describe "GET show with token" do
    let(:json) { JSON.parse(response.body) }
    let(:token) { AppStatus.auth_token }

    context "when true mail can verify valid e-mail address" do
      it "has HTTP status 200" do
        expect(Truemail).to receive(:valid?).with("hitobito@puzzle.ch").and_return(true)

        get :show, params: {token: token}

        expect(response.status).to eq(200)

        expect(json).to eq("app_status" =>
                           {"code" => "ok",
                            "details" => {
                              "memory_usage_determinable" => true,
                              "memory_usage_exceeds_limit" => false,
                              "memory_usage_limit_percentage" => 95,
                              "truemail_working" => true,
                              "validated_email" => "hitobito@puzzle.ch"
                            }})
      end
    end

    context "when true mail cannot verify valid e-mail address" do
      it "has HTTP status 503" do
        expect(Truemail).to receive(:valid?).with("hitobito@puzzle.ch").and_return(false)

        get :show, params: {token: token}

        expect(response.status).to eq(503)

        expect(json).to eq("app_status" =>
                           {"code" => "service_unavailable",
                            "details" => {
                              "memory_usage_determinable" => true,
                              "memory_usage_exceeds_limit" => false,
                              "memory_usage_limit_percentage" => 95,
                              "truemail_working" => false,
                              "validated_email" => "hitobito@puzzle.ch"
                            }})
      end
    end
  end

  describe "GET show without token" do
    let(:json) { JSON.parse(response.body) }

    context "when true mail can verify valid e-mail address" do
      it "has HTTP status 200" do
        expect(Truemail).to receive(:valid?).with("hitobito@puzzle.ch").and_return(true)

        get :show

        expect(response.status).to eq(200)

        expect(json).to eq("app_status" =>
                           {"code" => "ok",
                            "details" => {
                              "memory_usage_determinable" => true,
                              "memory_usage_exceeds_limit" => false,
                              "memory_usage_limit_percentage" => 95,
                              "truemail_working" => true
                            }})
      end
    end

    context "when true mail cannot verify valid e-mail address" do
      it "has HTTP status 503" do
        expect(Truemail).to receive(:valid?).with("hitobito@puzzle.ch").and_return(false)

        get :show

        expect(response.status).to eq(503)

        expect(json).to eq("app_status" =>
                           {"code" => "service_unavailable",
                            "details" => {
                              "memory_usage_determinable" => true,
                              "memory_usage_exceeds_limit" => false,
                              "memory_usage_limit_percentage" => 95,
                              "truemail_working" => false
                            }})
      end
    end

    context "when memory usage not determinable" do
      it "has HTTP status 503" do
        [
          "/sys/fs/cgroup/memory.max", "/sys/fs/cgroup/memory.current", "/sys/fs/cgroup/memory.stat"
        ].each do |memory_file|
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:exist?).with(memory_file).and_return(false)

          get :show

          expect(response.status).to eq(503)

          expect(json).to eq("app_status" =>
                             {"code" => "service_unavailable",
                              "details" => {
                                "memory_usage_determinable" => false,
                                "memory_usage_limit_percentage" => 95,
                                "truemail_working" => true
                              }})
        end
      end
    end
  end

  def stub_file_read(file, content)
    allow(File).to receive(:exist?).with(file).and_return(true)
    allow(File).to receive(:read).with(file).and_return(content)
  end
end
