# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::TextMessageProvider::Aspsms do

  let(:config) do
    { username: 'goofy',
    password: 'max42',
    originator: 'Acme' }
  end
  let(:provider) { described_class.new(config: config) }
  let(:success_response) do
    { StatusCode: '1',
      StatusInfo: 'OK' }.to_json
  end

  context '#send' do
    it 'sends text message to receivers' do
      stub_request(:post, 'https://json.aspsms.com/SendSimpleTextSMS').
        with(body: body, headers: headers).to_return(status: 200, body: success_response)

      result = provider.send(text: 'Hi Mickey! how are you today?', recipients: ['+4176000000'])
    end

    it 'creates one rest call per 1000 recipients' do
    end

    it 'handles invalid provider credentials' do
    end
  end

  private

  def body
    { UserName: 'goofy',
      Password: 'max42',
      Originator: 'Acme',
      MessageText: 'Hi Mickey! how are you today?',
      'Recipients':['+4176000000']
    }.to_json
  end

  def headers
    { 'Accept'=>'*/*',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Content-Length'=>'134',
      'Host'=>'json.aspsms.com',
    }
  end
end
