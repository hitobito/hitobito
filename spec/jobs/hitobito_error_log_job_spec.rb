# frozen_string_literal: true

#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe HitobitoErrorLogJob do
  include ActiveJob::TestHelper

  subject { HitobitoErrorLogJob.new }

  context "without recipient emails defined" do
    before do
      allow(Settings.hitobito_log).to receive(:recipient_emails).and_return(nil)
    end

    it "does not send any mails" do
      expect do
        subject.perform
      end.not_to have_enqueued_mail(HitobitoLogMailer, :error)
    end
  end

  context "with recipient emails defined" do
    before do
      allow(Settings.hitobito_log).to receive(:recipient_emails).and_return(["it@hitobito.example.com"])
    end

    it "reschedules to tomorrow at 5am" do
      subject.perform

      expect(subject.delayed_jobs.last.run_at).to eq(Time.zone.tomorrow
        .at_beginning_of_day
        .change(hour: 5)
        .in_time_zone)
    end

    it "sends email when error log entries exist in past 24 hours" do
      expect do
        subject.perform
      end.to have_enqueued_mail(HitobitoLogMailer, :error)
    end

    it "does not send email when no error log entries exist in past 24 hours" do
      HitobitoLogEntry.where(created_at: 2.days.ago..Time.zone.now).destroy_all
      expect do
        subject.perform
      end.not_to have_enqueued_mail(HitobitoLogMailer, :error)
    end

    it "does not include error logs not in certain time period" do
      expect(subject.send(:error_log_entry_ids)).to include(hitobito_log_entries(:error_ebics).id)
      expect(subject.send(:error_log_entry_ids)).not_to include(hitobito_log_entries(:error_webhook).id)
    end

    it "does not include logs without level error" do
      expect(subject.send(:error_log_entry_ids)).to include(hitobito_log_entries(:error_ebics).id)
      expect(subject.send(:error_log_entry_ids)).not_to include(hitobito_log_entries(:entry_with_payload).id)
    end

    context "#time_period" do
      it "uses 5am to 5am" do
        travel_to Time.zone.local(2005, 12, 9, 14) do
          expect(subject.send(:time_period).begin).to eq Time.zone.local(2005, 12, 8, 5)
          expect(subject.send(:time_period).end).to eq Time.zone.local(2005, 12, 9, 5)
        end
      end

      it "uses created_at as beginning if delayed job entry is found" do
        Delayed::Job.create!(handler: subject.to_yaml, created_at: Time.zone.local(2025, 2, 21))
        travel_to Time.zone.local(2025, 2, 24) do
          expect(subject.send(:time_period).begin).to eq Time.zone.local(2025, 2, 21, 5)
          expect(subject.send(:time_period).end).to eq Time.zone.local(2025, 2, 24, 5)
        end
      end

      it "uses 1 day ago as beginning if no delayed job entry is found" do
        travel_to Time.zone.local(2025, 2, 24) do
          expect(subject.send(:time_period).begin).to eq Time.zone.local(2025, 2, 23, 5)
          expect(subject.send(:time_period).end).to eq Time.zone.local(2025, 2, 24, 5)
        end
      end
    end
  end
end
