# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Address::CheckValidityJob do
  include ActiveJob::TestHelper

  let(:job) { Address::CheckValidityJob.new }
  let(:person) { people(:bottom_member) }
  let(:address) { addresses(:bs_bern) }

  context 'without addresses imported' do
    before do
      Address.delete_all
    end

    it 'does not run' do
      expect(Contactable::AddressValidator).to_not receive(:new)

      expect do
        perform_enqueued_jobs do
          job.perform
        end
      end.to_not change { ActionMailer::Base.deliveries.size }
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)
    end
  end

  context 'with addresses imported' do
    it 'sends email if invalid people are found and mail address is defined' do
      allow(Settings.addresses).to receive(:validity_job_notification_emails).and_return(['mail@example.com'])

      expect do
        perform_enqueued_jobs do
          job.perform
        end
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
      expect(ActsAsTaggableOn::Tagging.count).to eq(1)
    end

    it 'sends multiple emails if invalid people are found and multiple mail addresses is defined' do
      allow(Settings.addresses).to receive(:validity_job_notification_emails).and_return(['mail@example.com', 'addresses@example.com'])

      perform_enqueued_jobs do
        expect do
          job.perform
        end.to change { ActionMailer::Base.deliveries.size }.by(2)
        expect(ActsAsTaggableOn::Tagging.count).to eq(1)
      end
    end

    it 'sends no emails if no invalid people are found' do
      allow(Settings.addresses).to receive(:validity_job_notification_emails).and_return(['mail@example.com', 'addresses@example.com'])
      person.update!(address: address.street_short, zip_code: address.zip_code, town: address.town)

      perform_enqueued_jobs do
        expect do
          job.perform
        end.to_not change { ActionMailer::Base.deliveries.size }
        expect(ActsAsTaggableOn::Tagging.count).to eq(0)
      end
    end

    it 'sends no emails if no mail address is defined' do
      allow(Settings.addresses).to receive(:validity_job_notification_emails).and_return([])

      perform_enqueued_jobs do
        expect do
          job.perform
        end.to_not change { ActionMailer::Base.deliveries.size }
        expect(ActsAsTaggableOn::Tagging.count).to eq(1)
      end
    end

    it 'sends no emails if no invalid people are found and no mail address is defined' do
      allow(Settings.addresses).to receive(:validity_job_notification_emails).and_return([])

      person.update!(address: address.street_short, zip_code: address.zip_code, town: address.town)

      perform_enqueued_jobs do
        expect do
          job.perform
        end.to_not change { ActionMailer::Base.deliveries.size }
        expect(ActsAsTaggableOn::Tagging.count).to eq(0)
      end
    end
  end
end
