# frozen_string_literal: true

#  Copyright (c) 2024, Hitobito AG. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Payments::EbicsImportScheduleJob do
  include ActiveJob::TestHelper

  subject { Payments::EbicsImportScheduleJob.new }

  it "reschedules to tomorrow at 8am" do
    subject.perform

    expect(subject.delayed_jobs.last.run_at).to eq(Time.zone.tomorrow
                                                       .at_beginning_of_day
                                                       .change(hour: 8)
                                                       .in_time_zone)
  end

  it "schedules import job per initialized payment provider config" do
    initialized = payment_provider_configs(:postfinance).tap { _1.update(status: :registered) }

    expect(Payments::EbicsImportJob).to receive(:new).exactly(:once).with(initialized.id).and_call_original

    subject.perform
  end
end
