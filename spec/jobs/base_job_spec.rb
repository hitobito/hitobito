
require 'spec_helper'

describe BaseJob do
  def run_job(payload_object)
    payload_object.enqueue!.tap do |job_instance|
      Delayed::Worker.new.run(job_instance)
    end
  end

  it 'calls airbrake if an exception occurs' do
    allow_any_instance_of(BaseJob).to receive(:perform).and_raise('error')
    expect(Airbrake).to receive(:notify).and_call_original

    run_job(BaseJob.new)
  end

  context 'background_job_logging' do
    let(:notifications) { Hash.new {|h, k| h[k] = [] } }

    def subscribe
      callback = lambda do |name, started, finished, unique_id, payload|
        notifications[name] <<
          OpenStruct.new(name: name, started: started, finished: finished, unique_id: unique_id, payload: payload)
      end
      ActiveSupport::Notifications.subscribed(callback, /\w+\.background_job/) do
        yield
      end
    end

    it 'does not instrument notification with use_background_job_logging=false' do
      described_class.use_background_job_logging = false
      subscribe { run_job(BaseJob.new) }
      expect(notifications).to be_empty
    end

    it 'does instrument notification with use_background_job_logging=true' do
      described_class.use_background_job_logging = true
      job = subscribe { run_job(BaseJob.new) }

      expect(notifications.keys).to match_array [
        "job_started.background_job",
        "job_finished.background_job"
      ]

      expect(notifications["job_started.background_job"]).to have(1).item
      expect(notifications["job_finished.background_job"]).to have(1).item

      started_attrs = notifications["job_started.background_job"].first[:payload]
      expect(started_attrs).to match(
        job_id: job.id,
        job_name: described_class.name,
        group_id: nil,
        started_at: an_instance_of(ActiveSupport::TimeWithZone),
        attempt: 0
      )

      finished_attrs = notifications["job_finished.background_job"].first[:payload]
      expect(finished_attrs).to match(
        job_id: job.id,
        job_name: described_class.name,
        group_id: nil,
        finished_at: an_instance_of(ActiveSupport::TimeWithZone),
        status: 'success',
        payload: {},
        attempt: 0
      )
    end

    it 'does log group_id if implemented on job' do
      described_class.use_background_job_logging = true
      allow_any_instance_of(described_class).to receive(:group_id).and_return(42)

      subscribe { run_job(BaseJob.new) }

      expect(notifications.values.flatten).to all(have_attributes payload: a_hash_including(group_id: 42))
    end

    it 'includes job#log_results as payload on success' do
      expected_payload = {this: {is: ['the', :outcome]} }

      described_class.use_background_job_logging = true
      allow_any_instance_of(described_class).to receive(:log_results).and_return(expected_payload)

      subscribe { run_job(BaseJob.new) }

      expect(notifications.dig("job_finished.background_job", 0).payload[:payload]).to eq expected_payload
    end
  end

end
