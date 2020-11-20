# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Address::CheckValidityJob do

  let(:job) { Address::CheckValidityJob.new }
  let(:validator) { Contactable::AddressValidator.new }

  before do
    expect(Contactable::AddressValidator).to receive(:new).and_return(validator)
  end

  it 'sends email if invalid people are found and mail address is defined' do
    Settings.addresses.validity_job_notification_emails = ['mail@example.com']
    expect(validator).to receive(:validate_people).and_return([people(:bottom_member)])

    mail = double
    expect(mail).to receive(:deliver_now)

    expect(Address::ValidationChecksMailer).to receive(:validation_checks)
                  .with('mail@example.com', [people(:bottom_member)])
                  .exactly(:once)
                  .and_return(mail)

    job.perform
  end

  it 'sends multiple emails if invalid people are found and multiple mail addresses is defined' do
    Settings.addresses.validity_job_notification_emails = ['mail@example.com', 'addresses@example.com']

    expect(validator).to receive(:validate_people).and_return([people(:bottom_member)])

    mail = double
    expect(mail).to receive(:deliver_now).exactly(:twice)

    expect(Address::ValidationChecksMailer).to receive(:validation_checks)
                                           .with('mail@example.com', [people(:bottom_member)])
                                           .exactly(:once)
                                           .and_return(mail)

    expect(Address::ValidationChecksMailer).to receive(:validation_checks)
                  .with('addresses@example.com', [people(:bottom_member)])
                  .exactly(:once)
                  .and_return(mail)

    job.perform
  end

  it 'sends no emails if no invalid people are found' do
    Settings.addresses.validity_job_notification_emails = ['mail@example.com', 'addresses@example.com']

    expect(validator).to receive(:validate_people).and_return([])

    expect(Address::ValidationChecksMailer).to_not receive(:validation_checks)

    job.perform
  end

  it 'sends no emails if no mail address is defined' do
    Settings.addresses.validity_job_notification_emails = []

    expect(validator).to receive(:validate_people).and_return([people(:bottom_member)])

    expect(Address::ValidationChecksMailer).to_not receive(:validation_checks)

    job.perform
  end

  it 'sends no emails if no invalid people are found and no mail address is defined' do
    Settings.addresses.validity_job_notification_emails = []

    expect(validator).to receive(:validate_people).and_return([])

    expect(Address::ValidationChecksMailer).to_not receive(:validation_checks)

    job.perform
  end
end
