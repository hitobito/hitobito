# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Messages::TextMessageDeliveryReportJob do
  let(:message)    { messages(:sms) }
  let(:top_leader) { people(:top_leader) }
  let!(:mobile) { Fabricate(:phone_number, contactable: top_leader, label: 'Mobil') }
  let(:ok_report) { { status: :ok, status_message: '' } }
  let(:failed_report) { { status: :failed, status_message: '' } }
  let(:ok_delivery_reports) { { status: :ok, delivery_reports: { recipient.id.to_s => ok_report } } }
  let!(:recipient) do
    MessageRecipient.create!(
      { message_id: message.id,
        person_id: top_leader.id,
        phone_number: mobile1.number,
        state: :pending })
  end

  let(:client_double) { double(:client) }

  subject { described_class.new(message, client_double) }

  context 'on successfull delivery_reports' do
    it 'updates recipient status as sent' do
      expect(client_double).to receive(:delivery_reports).and_return(ok_delivery_reports)

      subject.perform

      recipient.reload

      expect(recipient.state).to eq('sent')
    end
  end
end
