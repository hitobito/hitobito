#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Synchronize::Mailchimp::Client do
  let(:mailing_list) { MailingList.new(mailchimp_api_key: '1234567890d66d25cc5c9285ab5a5552-us12', mailchimp_list_id: 2) }
  let(:top_leader)   { people(:top_leader) }
  let(:client)       { described_class.new(mailing_list, merge_fields: Synchronize::Mailchimp::Synchronizator.merge_fields) }


  def stub_collection(path, offset, count = client.count, body: )
    stub_request(:get, "https://us12.api.mailchimp.com/3.0/#{path}?count=#{count}&offset=#{offset}").
      with(
        headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>'Basic YXBpa2V5OjEyMzQ1Njc4OTBkNjZkMjVjYzVjOTI4NWFiNWE1NTUyLXVzMTI=',
          'Content-Type'=>'application/json',
          'User-Agent'=>'Faraday v0.15.3'

        }
    ).
    to_return(status: 200, body: body.to_json, headers: {})
  end

  def stub_merge_fields(*fields, total_items: nil, offset: 0)
    entries = fields.collect do |tag, name, type|
      { tag: tag, name: name, type: type }
    end
    stub_collection("lists/2/merge-fields", offset, body: { merge_fields: entries, total_items: total_items || entries.count})
  end

  def stub_members(*members, total_items: nil, offset: 0)
    entries = members.collect do |email, status = 'subscribed', tags = [], merge_fields = {}, extra_fields = {}|
      { email_address: email, status: status, tags: tags, merge_fields: merge_fields }.merge(extra_fields)
    end
    stub_collection("lists/2/members", offset, body: { members: entries, total_items: total_items || entries.count})
  end

  def stub_segments(*segments, total_items: nil, offset: 0)
    entries = segments.collect do |name, id|
      { name: name, id: id.to_i }
    end
    stub_collection("lists/2/segments", offset, body: { segments: entries, total_items: total_items || entries.count})
  end

  context '#subscriber_body' do

    it 'strips whitespace from fields' do
      top_leader.update(first_name: ' top ', last_name: ' leader ', email: ' top@example.com ')
      body = client.subscriber_body(top_leader)

      expect(body[:email_address]).to eq 'top@example.com'
      expect(body[:merge_fields][:FNAME]).to eq 'top'
      expect(body[:merge_fields][:LNAME]).to eq 'leader'
    end

    context 'merge_fields' do
      let(:merge_field) {
        [ 'Gender', 'dropdown', { choices: %w(m) },  ->(p) { p.gender } ]
      }
      let(:client) { described_class.new(mailing_list, merge_fields: [merge_field]) }

      it 'excludes blank value' do
        body = client.subscriber_body(top_leader)
        expect(body[:merge_fields]).not_to have_key :GENDER
      end

      it 'excludes present value that is not part of choices' do
        top_leader.update(gender: 'w')
        body = client.subscriber_body(top_leader)
        expect(body[:merge_fields]).not_to have_key :GENDER
      end

      it 'includes present value' do
        top_leader.update(gender: 'm')
        body = client.subscriber_body(top_leader)
        expect(body[:merge_fields][:GENDER]).to eq 'm'
      end
    end

    context 'member_fields' do
      let(:member_field) {
        [ :company, ->(p)  { p.company } ]
      }
      let(:client) { described_class.new(mailing_list, member_fields: [member_field]) }

      it 'excludes blank value' do
        body = client.subscriber_body(top_leader)
        expect(body).not_to have_key :company
      end

      it 'includes present value' do
        top_leader.update!(company: true, company_name: 'acme')
        body = client.subscriber_body(top_leader)
        expect(body[:company]).to eq true
      end
    end

    context 'synchronization flags' do
      before { top_leader.update(gender: 'w', nickname: 'Nick') }
      subject { client.subscriber_body(top_leader)[:merge_fields] }

      it 'includes all fields by default' do
        expect(subject).to have_key :FNAME
        expect(subject).to have_key :LNAME
        expect(subject).to have_key :NICKNAME
        expect(subject).to have_key :GENDER
      end

      it 'excludes when flags are set to false' do
        mailing_list.mailchimp_sync_first_name = false
        mailing_list.mailchimp_sync_last_name = false
        mailing_list.mailchimp_sync_nickname = false
        mailing_list.mailchimp_sync_gender = false

        expect(subject).not_to have_key :FNAME
        expect(subject).not_to have_key :LNAME
        expect(subject).not_to have_key :NICKNAME
        expect(subject).not_to have_key :GENDER
      end
    end
  end

  context '#merge_fields' do
    subject { client.fetch_merge_fields }

    it 'returns empty merge_fields list' do
      stub_merge_fields
      expect(subject).to be_empty
    end

    it 'returns merge_fields with id' do
      stub_merge_fields(['FNAME', 'First Name', 'text'],
                        ['GENDER', 'Gender', 'text'])
      expect(subject).to have(2).items

      first = subject.first
      expect(first[:tag]).to eq 'FNAME'
      expect(first[:name]).to eq 'First Name'
      expect(first[:type]).to eq 'text'

      second = subject.second
      expect(second[:tag]).to eq 'GENDER'
      expect(second[:name]).to eq 'Gender'
      expect(second[:type]).to eq 'text'
    end
  end

  context '#segments' do
    subject { client.fetch_segments }

    it 'returns empty segment list' do
      stub_segments
      expect(subject).to be_empty
    end

    it 'returns segments with id' do
      stub_segments(%w(a 1), %w(b 2))
      expect(subject).to have(2).items

      first = subject.first
      expect(first[:name]).to eq 'a'
      expect(first[:id]).to eq 1

      second = subject.second
      expect(second[:name]).to eq 'b'
      expect(second[:id]).to eq 2
    end
  end

  context '#members' do
    subject { client.fetch_members }

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

    it 'returns members with tags' do
      stub_members(['a@example.com', nil, [{ id: 1, name: 'test:ab' }, { id: 2, name: 'test' }]])
      expect(subject.first[:tags]).to eq [{ id: 1, name: 'test:ab' }, { id: 2, name: 'test' }]
    end

    it 'returns members with merge fields' do
      stub_members(['a@example.com', nil, nil, { FNAME: 'A', LNAME: 'B', GENDER: 'm' }])
      expect(subject.first[:merge_fields]).to eq({ FNAME: 'A', LNAME: 'B', GENDER: 'm' })
    end

    it 'returns members with custom member fields' do
      expect(client).to receive(:member_fields).and_return([['company']])
      stub_members(['a@example.com', nil, nil, {}, { company: :acme }])
      expect(subject.first[:company]).to eq 'acme'
    end


    context 'paging' do
      let(:client)       { described_class.new(mailing_list, count: 2) }

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

  context '#create_merge_field_operation' do
    subject { client.create_merge_field_operation('Gender', 'dropdown', { choices: %w(m w) }) }

    it 'POSTs to segments list resource' do
      expect(subject[:method]).to eq 'POST'
      expect(subject[:path]).to eq 'lists/2/merge-fields'
    end

    it 'body includes name and static_segment fields' do
      body = JSON.parse(subject[:body])
      expect(body['tag']).to eq 'GENDER'
      expect(body['name']).to eq 'Gender'
      expect(body['type']).to eq 'dropdown'
      expect(body['options']['choices']).to eq %w(m w)
    end
  end

  context '#create_segment_operation' do
    subject { client.create_segment_operation('a') }

    it 'POSTs to segments list resource' do
      expect(subject[:method]).to eq 'POST'
      expect(subject[:path]).to eq 'lists/2/segments'
    end

    it 'body includes name and static_segment fields' do
      body = JSON.parse(subject[:body])
      expect(body['name']).to eq 'a'
      expect(body['static_segment']).to eq []
    end
  end

  context '#create_segment executes batch' do
    before { expect(Settings.mailchimp).to receive(:max_attempts).and_return(3) }

    it 'raises if status does not change within max_attempts' do
      stub_request(:post, "https://us12.api.mailchimp.com/3.0/batches").
        to_return(status: 200, body: {id: 1}.to_json)

      stub_request(:get, "https://us12.api.mailchimp.com/3.0/batches/1").
        to_return(status: 200, body: {id: 1, status: 'pending' }.to_json)

      expect(client).to receive(:sleep).exactly(5).times
      expect do
        client.create_segments(%w(a))
      end.to raise_error RuntimeError, 'Batch 1 exeeded max_attempts, status: pending'
    end

    it 'succeeds if status changes to finished' do
      stub_request(:post, "https://us12.api.mailchimp.com/3.0/batches").
        to_return(status: 200, body: {id: 1}.to_json)

      stub_request(:get, "https://us12.api.mailchimp.com/3.0/batches/1").
        to_return(status: 200, body: {id: 1, status: 'pending' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'finished' }.to_json)

      expect(client).to receive(:sleep).exactly(2).times
      client.create_segments(%w(a))
    end

    it 'resets counts when status changes' do
      stub_request(:post, "https://us12.api.mailchimp.com/3.0/batches").
        to_return(status: 200, body: {id: 1}.to_json)

      stub_request(:get, "https://us12.api.mailchimp.com/3.0/batches/1").
        to_return(status: 200, body: {id: 1, status: 'pending' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'pending' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'pending' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'pre-processing' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'pre-processing' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'pre-processing' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'started' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'started' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'started' }.to_json).
        to_return(status: 200, body: {id: 1, status: 'finished' }.to_json)

      expect(client).to receive(:sleep).exactly(10).times
      client.create_segments(%w(a))
    end
  end

  context '#update_segment_operation' do
    subject { client.update_segment_operation(1, %w(leader@example.com member@example.com)) }

    it 'POSTs to segments list resource' do
      expect(subject[:method]).to eq 'POST'
      expect(subject[:path]).to eq "lists/2/segments/1"
    end

    it 'body includes name and static_segment fields' do
      body = JSON.parse(subject[:body])
      expect(body['members_to_add']).to eq %w(leader@example.com member@example.com)
    end
  end

  context '#subscribe_member_operation' do
    subject { client.subscribe_member_operation(top_leader) }

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

    it 'body includes member fields' do
      member_field = ['id', ->(p) { p.id }]
      expect(client).to receive(:member_fields).and_return([member_field])
      body = JSON.parse(subject[:body])
      expect(body['id']).to eq top_leader.id
    end

    it 'body includes merge fields' do
      merge_field = ['Gender', 'dropdown', { choices: %w(w m) }, ->(p) { p.gender }]
      expect(client).to receive(:merge_fields).and_return([merge_field])
      body = JSON.parse(subject[:body])
      expect(body['merge_fields']['GENDER']).to eq top_leader.gender
    end
  end

  context '#update_member_operation' do
    subject { client.update_member_operation(top_leader) }

    it 'POSTs to members list resource' do
      expect(subject[:method]).to eq 'PUT'
      expect(subject[:path]).to eq 'lists/2/members/f55f27b511af2735650c330490da54f5'
    end

    it 'body includes status, email_address, FNAME and LNAME fields' do
      body = JSON.parse(subject[:body])
      expect(body['email_address']).to eq 'top_leader@example.com'
      expect(body['merge_fields']['FNAME']).to eq 'Top'
      expect(body['merge_fields']['LNAME']).to eq 'Leader'
    end

    it 'body includes member fields' do
      member_field = ['id', ->(p) { p.id }]
      expect(client).to receive(:member_fields).and_return([member_field])
      body = JSON.parse(subject[:body])
      expect(body['id']).to eq top_leader.id
    end

    it 'body includes merge fields' do
      merge_field = ['Gender', 'dropdown', { choices: %w(w m) }, ->(p) { p.gender }]
      expect(client).to receive(:merge_fields).and_return([merge_field])
      body = JSON.parse(subject[:body])
      expect(body['merge_fields']['GENDER']).to eq top_leader.gender
    end
  end

  context '#unsubscribe_member_operation' do
    subject { client.unsubscribe_member_operation(@email) }

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
