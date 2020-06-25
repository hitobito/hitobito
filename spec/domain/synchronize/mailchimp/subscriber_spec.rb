require 'spec_helper'
require 'digest/md5'

describe Synchronize::Mailchimp::Subscriber do
  let(:person)       { people(:top_leader) }
  let(:mailing_list) { mailing_lists(:leaders) }

  before do
    mailing_list.subscriptions.create!(subscriber: person)
    person.additional_emails <<
      AdditionalEmail.new(label: 'vater', email: 'vater@example.com', mailings: true)
  end

  subject { described_class.mailing_list_subscribers(mailing_list) }

  context 'basic mailing list' do
    it 'returns all people once' do
      expect(subject.count).to eq(1)
    end

    it 'returns subscriber containing person' do
      expect(subject.first.email).to eq(person.email)
      expect(subject.first.person).to eq(person)
    end
  end

  context 'mailing list with mailchimp_include_additional_emails' do
    before do
      mailing_list.mailchimp_include_additional_emails = true
    end

    it 'returns an entry per people and address (default and additional)' do
      expect(subject.count).to eq(2)
      expect(subject.map(&:email)).to eq([person.email, 'vater@example.com'])
    end
  end
end
