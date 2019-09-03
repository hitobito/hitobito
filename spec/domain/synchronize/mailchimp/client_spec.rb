#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Synchronize::Mailchimp::Client do
  let(:mailing_list) { MailingList.new(mailchimp_api_key: '1234567890d66d25cc5c9285ab5a5552-us12', mailchimp_list_id: 2) }
  let(:top_leader)   { people(:top_leader) }
  let(:client)       { described_class.new(mailing_list) }

  def stub_members(*members, total_items: nil, offset: 0)
    entries = members.collect do |email, status|
      { email_address: email, status: status || 'subscribed' }
    end

    stub_request(:get, "https://us12.api.mailchimp.com/3.0/lists/2/members?count=#{client.count}&offset=#{offset}").
      with(
        headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>'Basic YXBpa2V5OjEyMzQ1Njc4OTBkNjZkMjVjYzVjOTI4NWFiNWE1NTUyLXVzMTI=',
          'Content-Type'=>'application/json',
          'User-Agent'=>'Faraday v0.15.3'

        }
    ).
    to_return(status: 200, body: { members: entries, total_items: total_items || entries.count }.to_json, headers: {})
  end

  context '#members' do
    subject { client.members }

    it 'returns empty member list' do
      stub_members
      expect(subject).to be_empty
    end

    it 'returns members with subscription state' do
      stub_members(%w(a@example.com subscribed), %w(b@example.com unsubscribed))
      expect(subject).to have(2).items

      first = subject.first
      expect(first[:email_address]).to eq 'a@example.com'
      expect(first[:status]).to eq 'subscribed'

      second = subject.second
      expect(second[:email_address]).to eq 'b@example.com'
      expect(second[:status]).to eq 'unsubscribed'
    end

    context 'paging' do
      let(:client)       { described_class.new(mailing_list, 2) }

      it 'fetches until total has been reached' do
        stub_members(%w(a@example.com), %w(b@example.com), total_items: 5)
        stub_members(%w(c@example.com), %w(d@example.com), total_items: 5, offset: 2)
        stub_members(%w(e@example.com), total_items: 5, offset: 4)
        expect(subject).to have(5).items

        users = subject.collect {|e| e[:email_address].split('@').first }
        expect(users).to eq %w(a b c d e)
      end
    end
  end

  context '#subscribe_operation' do
    subject { client.subscribe_operation(top_leader) }

    it 'POSTs to members list resource' do
      expect(subject[:method]).to eq 'POST'
      expect(subject[:path]).to eq 'lists/2/members'
    end


    it 'body includes status, email_address, FNAME and LNAME fields' do
      body = JSON.parse(subject[:body])
      expect(body['status']).to eq 'subscribed'
      expect(body['email_address']).to eq 'top_leader@example.com'
      expect(body['merge_fields']['FNAME']).to eq 'Top'
      expect(body['merge_fields']['LNAME']).to eq 'Leader'
    end
  end

  context '#delete_operation' do
    subject { client.delete_operation(@email) }

    it 'DELETEs email specific resource' do
      @email = 'top_leader@example.com'
      expect(subject[:method]).to eq 'DELETE'
      expect(subject[:path]).to eq 'lists/2/members/f55f27b511af2735650c330490da54f5'
    end

    it 'ignores case when calculating id' do
      @email = 'TOP_LEADER@EXAMPLE.COM'
      expect(subject[:path]).to eq 'lists/2/members/f55f27b511af2735650c330490da54f5'
    end

    it 'has different has for differnt email' do
      @email = 'top_leader1@example.com'
      expect(subject[:path]).to eq 'lists/2/members/d36e5c76dc67d95e935265cc451fc878'
    end
  end
end
