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

  it "schedules one import job per initialized invoice_config/payment_provider pair" do
    initialized = payment_provider_configs(:postfinance).tap { _1.update(status: :registered) }

    expect(Payments::EbicsImportJob).to receive(:new).exactly(:once)
      .with(initialized.invoice_config_id, initialized.payment_provider).and_call_original

    subject.perform
  end

  it "schedules only one job when both EBICS versions are initialized for the same pair" do
    postfinance = payment_provider_configs(:postfinance)
    postfinance.update!(status: :registered, legacy_25_ebics: false)
    postfinance.invoice_config.payment_provider_configs.create!(
      payment_provider: "postfinance", legacy_25_ebics: true, status: :registered
    )

    expect(Payments::EbicsImportJob).to receive(:new)
      .with(postfinance.invoice_config_id, "postfinance").exactly(:once).and_call_original

    subject.perform
  end
end
