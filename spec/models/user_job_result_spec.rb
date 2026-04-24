# frozen_string_literal: true

# == Schema Information
#
# Table name: async_download_files
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  filetype   :string
#  progress   :integer
#  person_id  :integer          not null
#  timestamp  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "spec_helper"

describe UserJobResult do
  let(:person_id) { 42 }
  let(:person) { Person.new(id: person_id) }
  let(:other_person) { Person.new(id: 23) }
  let(:job_name) { "A test job" }
  let(:filename) { "subscriptions_to-blorbaels-rants" }
  let(:filetype) { "csv" }
  let(:reports_progress) { false }
  let(:data) { SecureRandom.base64(128) }

  subject do
    UserJobResult.create!(person_id:, job_name:, filename:, filetype:, reports_progress:)
  end

  describe "default values" do
    before do
      freeze_time
    end

    it "should set correct default values when values are not passed" do
      user_job_result = UserJobResult.create!(person_id:, job_name:)

      check_default_values(user_job_result)
    end

    it "should set correct default values when values are passed as nil" do
      user_job_result = UserJobResult.create!(
        person_id:,
        job_name:,
        filetype: nil,
        start_timestamp: nil,
        status: nil,
        attempts: nil,
        max_attempts: nil,
        reports_progress: nil,
        progress: nil
      )

      check_default_values(user_job_result)
    end

    it "should not override values with default values when they are passed" do
      user_job_result_attributes = {
        person_id:,
        job_name:,
        filetype: "csv",
        start_timestamp: 10.days.ago,
        status: "in_progress",
        attempts: 3,
        max_attempts: 42,
        reports_progress: true,
        progress: 50
      }

      user_job_result = UserJobResult.create!(user_job_result_attributes)

      expect(user_job_result).to have_attributes(user_job_result_attributes)
    end

    def check_default_values(user_job_result)
      expect(user_job_result).to have_attributes(
        person_id: person_id,
        job_name: job_name,
        filename: nil,
        filetype: "txt",
        reports_progress: false,
        progress: 0,
        status: "planned",
        attempts: 0,
        max_attempts: Delayed::Worker.max_attempts,
        start_timestamp: Time.current
      )
    end
  end

  describe "filename handling" do
    it "should append filetype to filename in getter" do
      expect(subject.filename).to eql "#{filename}.#{filetype}"
    end

    # Tested because we append the filetype to the filename
    it "should have no filename when filename is nil" do
      subject.update!(filename: nil)

      expect(subject.filename).to be_nil
    end

    it "should have no filename when filename is blank" do
      subject.update!(filename: "")

      expect(subject.filename).to be_nil
    end

    it "should normalize filename in setter" do
      subject.filename = "A filename with  many   spaces"

      expect(subject.filename).to eql "A-filename-with-many-spaces.csv"
    end
  end

  describe "state reporting" do
    it "should correctly change model state when reporting in progress" do
      subject.report_in_progress!

      expect(subject.end_timestamp).to be_nil
      expect(subject.status).to eql("in_progress")
      expect(subject.attempts).to eql(0)
    end

    it "should correctly change model state when reporting success" do
      freeze_time
      subject.report_success!(1)

      expect(subject.end_timestamp).to eql(Time.current)
      expect(subject.status).to eql("success")
      expect(subject.attempts).to eql(1)
    end

    it "should correctly change model state when reporting error" do
      subject.report_error!(3)

      expect(subject.end_timestamp).to be_nil
      expect(subject.status).to eql("planned")
      expect(subject.attempts).to eql(3)
    end

    it "should correctly change model state when reporting failure" do
      freeze_time
      subject.update!(attempts: 3)
      subject.report_failure!

      expect(subject.end_timestamp).to eql(Time.current)
      expect(subject.status).to eql("error")
      expect(subject.attempts).to eql(3)
    end
  end

  describe "progress reporting" do
    it "should not report progress when reports_progress is false" do
      subject.report_progress!(49, 100)

      expect(subject.progress).to be_zero
    end

    it "should correctly set progress with 1 percent steps" do
      subject.update!(reports_progress: true)
      subject.update!(progress: 0)

      list = (0..1000)
      calculated_progress_values = []
      calculated_progress_values << subject.progress

      list.each do |i|
        subject.report_progress!(i, 1000)
        calculated_progress_values << subject.progress
      end

      expect(calculated_progress_values.uniq).to match_array((0..100).to_a)
    end

    it "should correctly set progress with 10 percent steps" do
      subject.update!(reports_progress: true)
      subject.update!(progress: 0)

      list = (0..1000)
      calculated_progress_values = []
      calculated_progress_values << subject.progress

      list.step(100) do |i|
        subject.report_progress!(i, 1000)
        calculated_progress_values << subject.progress
      end

      expect(calculated_progress_values.uniq).to match_array((0..100).step(10).to_a)
    end

    it "should not allow progress over 100" do
      subject.update!(reports_progress: true)
      subject.report_progress!(150, 100)

      expect(subject.progress).to eql(100)
    end

    it "should not allow progress under 0" do
      subject.update!(reports_progress: true)
      subject.report_progress!(-100, 100)

      expect(subject.progress).to eql(0)
    end
  end

  describe "broadcasting notifications" do
    it "should broadcast notification when reporting success" do
      expect { subject.report_success!(1) }.to have_broadcasted_to("user_job_result_notifications")
    end

    it "should broadcast notification when reporting failure" do
      expect { subject.report_failure! }.to have_broadcasted_to("user_job_result_notifications")
    end
  end

  describe "download permissions" do
    it "knows if the file is downloadable for a person" do
      file_double = double("attachement")
      expect(subject).to receive(:generated_file).and_return(file_double)
      expect(file_double).to receive(:attached?).and_return(true)

      expect(subject.downloadable?(person)).to be true
    end

    it "is not downloadable for a different person" do
      expect(subject.downloadable?(other_person)).to be false
    end
  end

  describe "attachment reading and writing" do
    it "allows writing data" do
      expect do
        subject.write(data)
      end.to change(subject.generated_file, :attached?).from(false).to(true)
    end

    it "allows reading data" do
      subject.update!(filetype: :txt)
      subject.write(data)

      expect(subject.read).to eql(data)
    end

    it "encodes data as csv when reading from csv file" do
      subject.write(data)
      read_data = subject.read

      expect(read_data).to eql(data)
      expect(read_data.encoding.to_s).to eql(Settings.csv.encoding)
    end
  end
end
