# frozen_string_literal: true

#  Copyright (c) 2023-2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::CleanupJob do
  subject(:job) { described_class.new }

  before do
    allow(Settings.people.cleanup_job).to receive(:enabled).and_return(true)
  end

  it "noops if everyhing is alright" do
    expect { job.perform }.not_to change { Person.count }
  end

  it "destroys person without roles" do
    person = Fabricate(:person)
    expect { job.perform }.to change { Person.count }.by(-1)
    expect { person.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "exception handling" do
    let(:error) { RuntimeError.new("ouch") }

    def expect_and_stub_errors_for(person, runner)
      expect(Airbrake).to receive(:notify)
        .exactly(:once)
        .with(kind_of(RuntimeError), hash_including(parameters: {person_id: person.id}))

      allow_any_instance_of(runner).to receive(:run) do |obj|
        next yield obj.instance_variable_get(:@person) if @seen
        @seen = true
        raise error
      end
    end

    it "continues and notifies if destroy fails" do
      first, second = 2.times.map { Fabricate(:person) }
      expect_and_stub_errors_for(first, People::Destroyer) { |person| person.destroy! }

      expect { job.perform }.to change { Person.count }.by(-1)
      expect { first.reload }.not_to raise_error
      expect { second.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "continues and notifies if minimize fails" do
      first, second = 2.times.map { Fabricate(:person) }
      event = Fabricate(:event, dates: [Event::Date.new(start_at: 1.months.ago)])
      Fabricate(:event_participation, event:, person: first)
      Fabricate(:event_participation, event:, person: second)

      expect_and_stub_errors_for(first, People::Minimizer) { |person| person.update!(minimized_at: Time.zone.now) }
      expect { job.perform }.to change { Person.where(minimized_at: nil).count }.by(-1)
      expect(first.reload.minimized_at).to be_nil
      expect(second.reload.minimized_at).to be_present
    end
  end
end
