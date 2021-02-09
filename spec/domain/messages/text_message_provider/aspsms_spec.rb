# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::TextMessageProvider::Aspsms do

  let(:config) do
    GroupSetting.new(
      username: 'goofy',
      password: 'max42',
      originator: 'Acme'
    )
  end
  let(:provider) { described_class.new(config: config) }
  let(:success_response) do
    { StatusCode: '1',
      StatusInfo: 'OK' }.to_json
  end

  let(:delivery_response) do
    { StatusCode: '0',
      StatusInfo: 'OK',
      DeliveryNotifications: [
        { TransactionReferenceNumber: '4242',
          DeliveryStatus: '0',
          DeliveryStatusDescription: 'Delivered',
          SubmissionDate: '2021-01-21T13:46:28Z',
          NotificationDate: '2021-01-21T13:46:34Z',
          Reasoncode: '000',
          ReasoncodeDescription: '' },
        { TransactionReferenceNumber: '4243',
          DeliveryStatus: '-1',
          DeliveryStatusDescription: 'Not yet submitted or rejected',
          SubmissionDate: '2021-01-21T13:49:28Z',
          NotificationDate: '2021-01-21T13:49:34Z',
          Reasoncode: ':',
          ReasoncodeDescription: '' }
      ] }.to_json
  end

  context '#send' do
    it 'sends text message to receivers' do
      stub_request(:post, 'https://json.aspsms.com/SendSimpleTextSMS')
        .with(body: send_body, headers: headers).to_return(status: 200, body: success_response)

      result = provider.send(text: 'Hi Mickey! how are you today?', recipients: recipients)
      expect(result[:status]).to eq(:ok)
      expect(result[:message]).to eq('OK')
    end

    it 'does not send to more than 1000 recipients' do
      @recipients_count = 1042
      stub_request(:post, 'https://json.aspsms.com/SendSimpleTextSMS')
        .with(body: send_body, headers: headers).to_return(status: 200, body: success_response)

      result = provider.send(text: 'Hi Mickey! how are you today?', recipients: recipients)
      expect(result[:status]).to eq(:ok)
      expect(result[:message]).to eq('OK')
    end

    it 'handles invalid provider credentials' do
      auth_error_response = { StatusCode: '3', StatusInfo: 'Authorization failed.' }.to_json
      stub_request(:post, 'https://json.aspsms.com/SendSimpleTextSMS')
        .with(body: send_body, headers: headers).to_return(status: 200, body: auth_error_response)

      result = provider.send(text: 'Hi Mickey! how are you today?', recipients: recipients)
      expect(result[:status]).to eq(:auth_error)
      expect(result[:message]).to eq('Authorization failed.')
    end
  end

  context '#delivery_reports' do
    it 'returns delivery report for given recipient id' do
      stub_request(:post, 'https://json.aspsms.com/InquireDeliveryNotifications')
        .with(body: delivery_report_body, headers: headers)
        .to_return(status: 200, body: delivery_response)

      result = provider.delivery_reports(recipient_ids: [4242, 4243])
      expect(result[:status]).to eq(:ok)
      expect(result[:message]).to eq('OK')

      delivery_reports = result[:delivery_reports]
      expect(delivery_reports.count).to eq(2)
      expect(delivery_reports['4242'][:status]).to eq(:ok)
      expect(delivery_reports['4242'][:status_message]).to eq('Delivered')
      expect(delivery_reports['4243'][:status]).to eq(:error)
      expect(delivery_reports['4243'][:status_message]).to eq('Not yet submitted or rejected')
    end

    it 'handles invalid provider credentials' do
      auth_error_response = { StatusCode: '3', StatusInfo: 'Authorization failed.' }.to_json
      stub_request(:post, 'https://json.aspsms.com/InquireDeliveryNotifications')
        .with(body: delivery_report_body, headers: headers)
        .to_return(status: 200, body: auth_error_response)

      result = provider.delivery_reports(recipient_ids: [4242, 4243])

      expect(result[:status]).to eq(:auth_error)
      expect(result[:message]).to eq('Authorization failed.')
    end
  end

  private

  def send_body
    { UserName: 'goofy',
      Password: 'max42',
      Originator: 'Acme',
      MessageText: 'Hi Mickey! how are you today?',
      Recipients: recipients[0..999] }.to_json
  end

  def delivery_report_body
    { UserName: 'goofy',
      Password: 'max42',
      TransactionReferenceNumbers: '4242;4243' }.to_json
  end

  def headers
    { Accept: '*/*',
      'Accept-Encoding': 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      Host: 'json.aspsms.com' }
  end

  def recipients
    @recipients ||= collect_recipients
  end

  def collect_recipients
    if @recipients_count
      r = []
      @recipients_count.times do
        r << Faker::Base.numerify('+41 77 ### ## ##')
      end
      r
    else
      ['+4176000000']
    end
  end
end
