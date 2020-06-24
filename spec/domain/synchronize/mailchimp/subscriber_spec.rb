require 'spec_helper'
require 'digest/md5'

describe Synchronize::Mailchimp::Subscriber do
  let(:user)         { people(:top_leader) }
  let(:mailing_list) { mailing_lists(:leaders) }

  before do
    mailing_list.subscriptions.create!(subscriber: user)
  end

  subject { described_class.mailing_list_subscribers(mailing_list) }

  context 'basic mailing list' do
    it 'returns all people once' do
      expect(subject.count).to eq(1)
    end

    it 'returns subscriber containing person' do
      expect(subject.first.email).to eq(user.email)
      expect(subject.first.person).to eq(user)
    end
  end
end
