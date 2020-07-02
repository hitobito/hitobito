require 'spec_helper'
require 'digest/md5'

describe Synchronize::Mailchimp::Subscriber do
  let(:person)       { people(:top_leader) }

  context "subscriber instance" do
    let(:subscriber) { described_class.new(person, "test@example.com") }

    it "acts as proxy to person" do
      expect(subscriber.id).to eq(person.id)
    end

    it "returns given email address instead of person's" do
      expect(subscriber.email).to eq("test@example.com")
    end
  end

  context '#mailing_list_subscribers (synchronization strategies)' do
    let(:mailing_list) { mailing_lists(:leaders) }

    before do
      mailing_list.subscriptions.create!(subscriber: person)
      person.additional_emails <<
        AdditionalEmail.new(label: 'vater', email: 'vater@example.com', mailings: true)
    end

    subject { described_class.mailing_list_subscribers(mailing_list) }

    context 'default strategy' do
      it 'returns all people once' do
        expect(subject.count).to eq(1)
      end

      it 'returns subscriber containing person' do
        expect(subject.first.email).to eq(person.email)
        expect(subject.first.person).to eq(person)
      end
    end

    context 'strategy to include additional emails' do
      before do
        mailing_list.mailchimp_include_additional_emails = true
      end

      it 'returns an entry per person and email (default and additional)' do
        expect(subject.count).to eq(2)
        expect(subject.map(&:email)).to eq([person.email, 'vater@example.com'])
      end
    end
  end
end
