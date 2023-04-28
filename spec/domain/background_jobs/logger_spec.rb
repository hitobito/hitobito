# encoding: utf-8

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe BackgroundJobs::Logger do
  %w[job_started job_finished].each do |event_name|
    it "subscribes to #{event_name}.background_job" do
      expect_any_instance_of(BackgroundJobs::Logger).to receive(event_name)
      ActiveSupport::Notifications.instrument("#{event_name}.background_job")
    end

    describe "##{event_name}" do
      it 'creates BackgroundJobEntry' do
        message = OpenStruct.new(payload: {
          job_id: 42,
          job_name: 'SomeJob',
          group_id: 43,
          started_at: Time.zone.at(1),
          finished_at: Time.zone.at(2),
          attempt: 44,
          status: 'unreal',
          payload: { some: ['random', :stuff, 45]}
        })

        expect { subject.public_send(event_name, message) }.to change { BackgroundJobLogEntry.count }.by(1)

        entry = BackgroundJobLogEntry.last
        message.payload.except(:payload).each do |attr,value|
          expect(entry.public_send(attr)).to eq(value),
            "\nexpected #{attr} to eq #{value.inspect}, got #{entry.send(attr).inspect}\n"
        end
        expect(entry.payload).to eq('some' => ['random', 'stuff', 45])
      end

      it 'with matching identifying attrs updates BackgroundJobEntry' do
        entry = BackgroundJobLogEntry.create!(job_id: 42, job_name: 'SomeJob', attempt: 7)

        message = OpenStruct.new(payload: { job_id: 42, job_name: 'SomeJob', attempt: 8, finished_at: Time.at(42) })
        expect { subject.public_send(event_name, message) }.not_to change { entry.reload.finished_at }

        message = OpenStruct.new(payload: { job_id: 42, job_name: 'SomeJob', attempt: 7, finished_at: Time.at(42) })
        expect { subject.public_send(event_name, message) }.to change { entry.reload.finished_at }
      end

      it 'ignores unknown attrs' do
        message = OpenStruct.new(payload: { job_id: 42, job_name: 'SomeJob', hello: :world })

        expect { subject.public_send(event_name, message) }.to change { BackgroundJobLogEntry.count }.by(1)
      end
    end
  end
end
