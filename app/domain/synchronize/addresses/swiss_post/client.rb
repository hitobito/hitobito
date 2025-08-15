# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Synchronize::Addresses::SwissPost
  class Client
    def test
      make_request("/ping")
    end

    def upload_file(payload)
      make_request(
        "/uploadfile",
        method: :post,
        payload:,
        content_type: "application/octet-stream",
        read_path: "UploadFileResult.FileToken"
      )
    end

    def create_file
      make_request("/createfile", read_path: "CreateFileResult.FileToken")
    end

    def run_batch(input_file_token, output_file_token)
      make_request(
        "/runbatch",
        method: :post,
        payload: build_run_batch_payload(input_file_token, output_file_token),
        content_type: "application/json",
        read_path: "RunBatchResult.BatchToken"
      )
    end

    def check_batch_status(batch_token)
      make_request("/checkbatchstatus/#{batch_token}",
        read_path: "CheckBatchStatusResult.BatchStatus.TokenStatus")
    end

    def download_file(output_token)
      make_request("/downloadfile/#{output_token}",
        read_path: nil).body.force_encoding(Config::ENCODING).encode("UTF-8")
    end

    private

    def make_request(path, method: :get, payload: nil, read_path: nil, content_type: nil)
      headers = auth_header
      headers["Content-Type"] = content_type if content_type

      response = RestClient::Request.execute(method:, url: endpoint(path), payload:, headers:)
      read_path ? JSON.parse(response.body).dig(*read_path.split(".")) : response
    end

    def build_run_batch_payload(input_file_token, output_file_token)
      {
        key: config.batch_key,
        replaceItems: [
          {
            Search: "{###INPUTFILE###}",
            Replacement: input_file_token
          },

          {
            Search: "{###OUTPUTFILE###}",
            Replacement: output_file_token
          }
        ]
      }.to_json
    end

    def endpoint(path) = [Config.host, Config.path, path].join

    def auth_header = {Authorization: "Basic #{auth_credentials}"}

    def auth_credentials = Base64.strict_encode64("#{config.username}:#{config.password}")

    def config = Config
  end
end
