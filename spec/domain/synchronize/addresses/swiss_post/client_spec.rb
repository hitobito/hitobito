# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Synchronize::Addresses::SwissPost::Client do
  let(:result) { Rails.root.join("spec", "support", "synchronize", "addresses", "swiss_post", "result.txt").read }
  let(:top_leader) { people(:top_leader) }
  let(:config) {
    {
      host: "https://addr.example.com",
      path: "/api/v1",
      username: "api",
      password: "secret",
      query_key: "Q1",
      batch_key: "B1"
    }
  }

  before do
    Synchronize::Addresses::SwissPost::Config.instance_variable_set(:@config, config.stringify_keys)
  end

  def stub_api_request(method, path, status: 200, payload: nil, response: "")
    url = [Synchronize::Addresses::SwissPost::Config.host, Synchronize::Addresses::SwissPost::Config.path, path].join
    stub_request(method, url)
      .with(headers: {Authorization: "Basic YXBpOnNlY3JldA=="})
      .to_return(status:, body: response)
  end

  subject(:client) { described_class.new }

  it "#test is truthy if server responds with 200" do
    stub_api_request(:get, "/ping")
    expect(client.test).to be_truthy
  end

  it "#test raises if server responds with unexpected response code " do
    stub_api_request(:get, "/ping", status: 401)
    expect { client.test }.to raise_error(RestClient::Unauthorized)
  end

  it "#test includes authorization header" do
    stub_api_request(:get, "/ping")
    expect(client.test).to be_truthy
  end

  it "#upload_file uploads the input file to the service returns a referencing token" do
    stub_api_request(:post, "/uploadfile", response: {UploadFileResult: {FileToken: "token"}}.to_json)
      .with(body: "payload", headers: {"Content-Type" => "application/octet-stream"})
    expect(client.upload_file("payload")).to eq "token"
  end

  it "#create_file creates a file to write the output to and returns a referencing token" do
    stub_api_request(:get, "/createfile", response: {CreateFileResult: {FileToken: "token"}}.to_json)
    expect(client.create_file).to eq "token"
  end

  it "#run_batch starts batch run and returns a referencing token" do
    body = {
      key: "B1",
      replaceItems: [
        {
          Search: "{###INPUTFILE###}",
          Replacement: "in"
        },
        {
          Search: "{###OUTPUTFILE###}",
          Replacement: "out"
        }
      ]
    }
    stub_api_request(:post, "/runbatch", response: {RunBatchResult: {BatchToken: "token"}}.to_json)
      .with(body:, headers: {"Content-Type" => "application/json"})
    expect(client.run_batch("in", "out")).to eq "token"
  end

  it "#check_batch_status creates a file to write the output to and returns a referencing token" do
    stub_api_request(:get, "/checkbatchstatus/token", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: "3"}}}.to_json)
    expect(client.check_batch_status("token")).to eq "3"
  end

  it "#download_file downloads result file and encodes to UTF-8" do
    stub_api_request(:get, "/downloadfile/token", response: "terminée".encode("Windows-1252"))
    file = client.download_file("token")
    expect(file).to eq "terminée"
    expect(file.encoding.to_s).to eq "UTF-8"
  end
end
