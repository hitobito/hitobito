# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe AddressSynchronizationJob do
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
    allow(described_class).to receive(:role_types).and_return(role_types)
    allow(described_class).to receive(:person_constraints).and_return({})
  end

  subject(:job) { described_class.new }

  def stub_api_request(method, path, status: 200, payload: nil, response: "")
    url = [Synchronize::Addresses::SwissPost::Config.host, Synchronize::Addresses::SwissPost::Config.path, path].join
    stub_request(method, url)
      .with(headers: {Authorization: "Basic YXBpOnNlY3JldA=="})
      .to_return(status:, body: response)
  end

  context "empty scope" do
    let(:role_types) { [] }

    it "does not enqueue job on empty scope" do
      expect { job.perform }.not_to change { Delayed::Job.count }
    end

    it "does not create log entry entry" do
      expect { job.perform }.not_to change { HitobitoLogEntry.count }
    end
  end

  context "present scope" do
    let(:role_types) { ["Group::BottomLayer::Member", "Group::TopGroup::Leader"] }
    let(:result) { Rails.root.join("spec", "support", "synchronize", "addresses", "swiss_post", "result.txt").read }
    let(:top_leader) { people(:top_leader) }

    def stub_batch_creation(upload_token: :in, result_token: :out, batch_token: :batch)
      stub_api_request(:post, "/uploadfile", response: {UploadFileResult: {FileToken: upload_token}}.to_json)
      stub_api_request(:get, "/createfile", response: {CreateFileResult: {FileToken: result_token}}.to_json)
      stub_api_request(:post, "/runbatch", response: {RunBatchResult: {BatchToken: batch_token}}.to_json)
    end

    before { stub_batch_creation }

    def parse_upload(req)
      CSV.parse(req.body, headers: true, row_sep: "\r\n", col_sep: "\t")
    end

    it "uploads TSV file with both people" do
      stub_api_request(:post, "/uploadfile", response: {UploadFileResult: {FileToken: :in}}.to_json).with do |req|
        data = parse_upload(req)
        expect(data.headers).to eq ["KDNR (QSTAT)", "Firma", "Vorname", "Nachname", "c/o", "Strasse", "Hausnummer", "Postfach", "PLZ", "Ort"]
        expect(data.entries.size).to eq 2
        expect(data.entries.first.to_h.values).to eq ["382461928", nil, "Bottom", "Member", nil, "Greatstreet", "345", nil, "3456", "Greattown"]
        expect(data.entries.second.to_h.values).to eq ["572407901", nil, "Top", "Leader", nil, "Greatstreet", "345", nil, "3456", "Greattown"]
      end
      job.perform
    end

    it "only uploads person once" do
      Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group), person: people(:bottom_member))
      stub_api_request(:post, "/uploadfile", response: {UploadFileResult: {FileToken: :in}}.to_json).with do |req|
        expect(parse_upload(req).entries.size).to eq 2
      end
      job.perform
    end

    it "does create log entry" do
      expect { job.perform }.to change { HitobitoLogEntry.count }.by(1)
        .and change { Delayed::Job.count }.by(1)

      expect(HitobitoLogEntry.last.level).to eq "info"
      expect(HitobitoLogEntry.last.category).to eq "cleanup"
      expect(HitobitoLogEntry.last.message).to eq "Post Adressabgleich: Fortschritt 0%"
    end

    it "enqueues follow up job to pull results" do
      expect { job.perform }.to change { Delayed::Job.count }.by(1)
      followup_job = Delayed::Job.last.payload_object
      expect(followup_job.result_token).to eq "out"
      expect(followup_job.batch_token).to eq "batch"
      expect(followup_job.cursor).to eq people(:top_leader).id
      expect(followup_job.processed_count).to eq 0
      expect(followup_job.processing_count).to eq 2
    end

    [0, 2, 3].each do |state|
      it "reschedules if job is still processing state #{state}" do
        expect { job.perform }.to change { Delayed::Job.count }.by(1)
        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: state}}}.to_json)
        Delayed::Job.last.payload_object.perform
        followup_job = Delayed::Job.last.payload_object
        expect(followup_job.result_token).to eq "out"
        expect(followup_job.batch_token).to eq "batch"
        expect(followup_job.cursor).to eq people(:top_leader).id
        expect(followup_job.processed_count).to eq 0
        expect(followup_job.processing_count).to eq 2
      end
    end

    describe "finished batch" do
      it "triggers download result processing" do
        job.perform
        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 4}}}.to_json)
        stub_api_request(:get, "/downloadfile/out", response: result.encode("Windows-1252"))
        expect do
          Delayed::Job.last.payload_object.perform
        end.to change { top_leader.reload.housenumber.to_i }.to(123)
          .and not_change { Delayed::Job.count }
        expect(HitobitoLogEntry.last.level).to eq "info"
        expect(HitobitoLogEntry.last.category).to eq "cleanup"
        expect(HitobitoLogEntry.last.message).to eq "Post Adressabgleich: Fortschritt 100%"
      end

      it "persists result as attachment via dj callback" do
        job.perform
        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 4}}}.to_json)
        stub_api_request(:get, "/downloadfile/out", response: result.encode("Windows-1252"))
        expect do
          travel_to(1.minute.from_now) do
            Delayed::Worker.new.work_off
          end
        end.to change { top_leader.reload.housenumber.to_i }.to(123)
          .and change { ActiveStorage::Attachment.count }.by(1)
        expect(ActiveStorage::Attachment.last.blob.open(&:read)).to eq result
      end
    end

    context "with reduced batch size" do
      before { job.batch_size = 1 }

      def run_next_job
        travel 1.minute
        Delayed::Job.last.payload_object.perform
      end

      it "upload respects batch size and enqueues with matching parameters" do
        stub_api_request(:post, "/uploadfile", response: {UploadFileResult: {FileToken: :in}}.to_json).with do |req|
          expect(parse_upload(req).entries.size).to eq 1
        end
        job.perform

        followup_job = Delayed::Job.last.payload_object
        expect(followup_job.cursor).to eq people(:bottom_member).id
        expect(followup_job.processed_count).to eq 0
        expect(followup_job.processing_count).to eq 1
      end

      it "proceeds with next batch in case current batch fails" do
        job.perform
        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 1}}}.to_json)
        expect do
          run_next_job
        end.to change { Delayed::Job.count }.by(1)

        expect(HitobitoLogEntry.second_to_last.level).to eq "error"
        expect(HitobitoLogEntry.second_to_last.category).to eq "cleanup"
        expect(HitobitoLogEntry.second_to_last.message).to eq "Post Adressabgleich: Fehler beim Verarbeiten von in"

        expect(HitobitoLogEntry.last.level).to eq "info"
        expect(HitobitoLogEntry.last.category).to eq "cleanup"
        expect(HitobitoLogEntry.last.message).to eq "Post Adressabgleich: Fortschritt 50%"

        followup_job = Delayed::Job.last.payload_object
        expect(followup_job.result_token).to eq "out"
        expect(followup_job.batch_token).to eq "batch"
        expect(followup_job.cursor).to eq people(:top_leader).id
        expect(followup_job.processed_count).to eq 1
        expect(followup_job.processing_count).to eq 1
      end

      it "does not log same progress percentage twice" do
        expect do
          job.perform
        end.to change { HitobitoLogEntry.count }.by(1)
        expect(HitobitoLogEntry.last.message).to eq "Post Adressabgleich: Fortschritt 0%"
        expect(Delayed::Job.last.payload_object.cursor).to eq people(:bottom_member).id

        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 3}}}.to_json)
        expect do
          run_next_job
        end.not_to change { HitobitoLogEntry.count }
        expect(Delayed::Job.last.payload_object.cursor).to eq people(:bottom_member).id

        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 4}}}.to_json)
        stub_api_request(:get, "/downloadfile/out", response: result.lines.take(2).join("\r\n").encode("Windows-1252"))

        expect do
          run_next_job
        end.to change { HitobitoLogEntry.count }
          .and not_change { top_leader.reload.housenumber }
        expect(HitobitoLogEntry.last.message).to eq "Post Adressabgleich: Fortschritt 50%"
        expect(Delayed::Job.last.payload_object.cursor).to eq people(:top_leader).id

        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 3}}}.to_json)
        expect do
          run_next_job
        end.to not_change { HitobitoLogEntry.count }
          .and not_change { top_leader.reload.housenumber }

        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 4}}}.to_json)
        stub_api_request(:get, "/downloadfile/out", response: result.lines.tap { |l| l.delete_at(1) }.join("\r\n").encode("Windows-1252"))

        expect do
          run_next_job
        end.to change { HitobitoLogEntry.count }
          .and change { top_leader.reload.housenumber }
          .and not_change { Delayed::Job.count }
        expect(HitobitoLogEntry.last.message).to eq "Post Adressabgleich: Fortschritt 100%"
      end

      it "runs three times before finalizing" do
        job.perform
        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 3}}}.to_json)
        expect do
          Delayed::Job.last.payload_object.perform
        end.to change { Delayed::Job.count }.by(1)

        followup_job = Delayed::Job.last.payload_object
        expect(followup_job.result_token).to eq "out"
        expect(followup_job.batch_token).to eq "batch"
        expect(followup_job.cursor).to eq people(:bottom_member).id
        expect(followup_job.processed_count).to eq 0
        expect(followup_job.processing_count).to eq 1

        stub_api_request(:get, "/checkbatchstatus/batch", response: {CheckBatchStatusResult: {BatchStatus: {TokenStatus: 4}}}.to_json)
        stub_api_request(:get, "/downloadfile/out", response: result.encode("Windows-1252"))
        expect do
          followup_job.perform
        end.to change { top_leader.reload.housenumber.to_i }.to(123)
          .and change { Delayed::Job.count }
      end
    end
  end
end
