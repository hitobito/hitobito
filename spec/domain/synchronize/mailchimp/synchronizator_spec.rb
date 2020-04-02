require 'spec_helper'
require 'digest/md5'

describe Synchronize::Mailchimp::Synchronizator do
  let(:user)         { people(:top_leader) }
  let(:other)        { people(:bottom_member) }
  let(:mailing_list) { mailing_lists(:leaders) }
  let(:sync)         { Synchronize::Mailchimp::Synchronizator.new(mailing_list) }
  let(:client)       { sync.client }

  let(:tags)         { %w(foo bar) }
  let(:merge_field) {
    [ 'Gender', 'dropdown', { choices: %w(m w) }, ->(p) { person.gender } ]
  }


  def segments(names)
    names.collect.each_with_index do |name, index|
      { id: index, name: name, member_count: 0 }
    end
  end

  def member(person, tags = [])
    sync.client.subscriber_body(person).merge(tags: tags)
  end

  context '#missing_merge_fields' do
    before  { sync.merge_fields = [] }

    subject { sync.missing_merge_fields }

    it 'is empty when no merge_fields is empty' do
      allow(sync.client).to receive(:fetch_merge_fields).and_return([])
      expect(subject).to be_empty
    end

    it 'includes local merge_field that does not exist remotely' do
      sync.merge_fields = [merge_field]
      allow(sync.client).to receive(:fetch_merge_fields).and_return([])
      expect(subject).to eq [merge_field]
    end

    it 'is empty when merge_field exists locally and remotely' do
      sync.merge_fields = [merge_field]
      allow(sync.client).to receive(:fetch_merge_fields).and_return([{ tag: 'GENDER', }])
      expect(subject).to be_empty
    end
  end

  context '#missing_segments' do
    subject { sync.missing_segments }

    it 'is empty when subscribers have no tags' do
      allow(sync.client).to receive(:fetch_segments).and_return([])
      mailing_list.subscriptions.create!(subscriber: user)
      expect(subject).to be_empty
    end

    it 'is includes local tag if it does not exist remotely' do
      allow(sync.client).to receive(:fetch_segments).and_return([])
      mailing_list.subscriptions.create!(subscriber: user)
      user.update(tag_list: %w(foo))
      expect(subject).to eq %w(foo)
    end

    it 'is includes other local tag if it does not exist remotely' do
      allow(sync.client).to receive(:fetch_segments).and_return([])
      mailing_list.subscriptions.create!(subscriber: user)
      user.update(tag_list: %w(foo bar))
      allow(sync.client).to receive(:fetch_segments).and_return(segments(%w(foo)))
      expect(subject).to eq %w(bar)
    end

    it 'is empty if both tags exists remotely' do
      allow(sync.client).to receive(:fetch_segments).and_return(segments(%w(foo bar)))
      mailing_list.subscriptions.create!(subscriber: user)
      user.update(tag_list: %w(foo bar))
      expect(subject).to be_empty
    end
  end

  context '#obsolete_segment_ids' do
    subject { sync.obsolete_segment_ids }

    it 'is empty when no remote segments exist' do
      allow(sync.client).to receive(:fetch_segments).and_return([])
      expect(subject).to be_empty
    end

    it 'is present if no local tag exists for remote segment' do
      allow(sync.client).to receive(:fetch_segments).and_return(segments(%w(foo)))
      expect(subject).to eq [0]
    end

    it 'is empty if local tag exists remotely' do
      allow(sync.client).to receive(:fetch_segments).and_return(segments(%w(foo)))
      mailing_list.subscriptions.create!(subscriber: user)
      user.update(tag_list: %w(foo))
      expect(subject).to be_empty
    end
  end

  context '#stale_segments' do
    subject { sync.stale_segments }

    it 'is empty when no tags are defined' do
      mailing_list.subscriptions.create!(subscriber: user)
      expect(sync.client).to receive(:fetch_segments).and_return([])
      expect(subject).to eq []
    end

    it 'is empty when we have only local tags' do
      user.update(tag_list: tags)
      mailing_list.subscriptions.create!(subscriber: user)

      expect(sync.client).to receive(:fetch_members).and_return([])
      expect(sync.client).to receive(:fetch_segments).and_return([])
      expect(subject).to eq []
    end

    it 'contains diff when remote has stale tag' do
      mailing_list.subscriptions.create!(subscriber: user)
      mailing_list.subscriptions.create!(subscriber: other)
      user.update(tag_list: tags)
      other.update(tag_list: tags.take(1))

      expect(sync.client).to receive(:fetch_members).and_return([
        member(user, segments(tags)),
        member(other, segments(tags)),
      ])
      expect(sync.client).to receive(:fetch_segments).and_return(segments(tags))
      expect(subject).to eq [[1, %w(top_leader@example.com)]]
    end

    it 'contains diff when local has extra tags' do
      mailing_list.subscriptions.create!(subscriber: user)
      mailing_list.subscriptions.create!(subscriber: other)
      user.update(tag_list: tags)
      other.update(tag_list: tags)

      expect(sync.client).to receive(:fetch_members).and_return([
        member(user, segments(tags).take(1)),
        member(other, segments(tags).take(1)),
      ])
      expect(sync.client).to receive(:fetch_segments).and_return(segments(tags))
      expect(subject).to have(1).item
      expect(subject.first.first).to eq 1
      expect(subject.first.second.sort).to eq %w(bottom_member@example.com top_leader@example.com)
    end

    it 'is empty when all local tags exist remotely' do
      user.update(tag_list: tags)
      mailing_list.subscriptions.create!(subscriber: user)

      expect(sync.client).to receive(:fetch_members).and_return([member(user, segments(tags))])
      expect(sync.client).to receive(:fetch_segments).and_return(segments(tags))
      expect(subject).to eq []
    end
  end

  context '#missing_people' do
    subject { sync.missing_people }

    it 'is empty without subscriptions' do
      expect(subject).to be_empty
    end

    it 'includes subscribers email if it does not exist remotely' do
      mailing_list.subscriptions.create!(subscriber: user)

      expect(client).to receive(:fetch_members).and_return([])
      expect(subject).to eq([user])
    end

    it 'is empty if email does exist remotely' do
      mailing_list.subscriptions.create!(subscriber: user)

      expect(client).to receive(:fetch_members).and_return([member(user)])
      expect(subject).to be_empty
    end
  end

  context '#obsolete_emails' do
    subject { sync.obsolete_emails }

    it 'is empty when remote is empty' do
      expect(sync.client).to receive(:fetch_members).and_return([])
      expect(subject).to be_empty
    end

    it 'includes email email remotely email does not exist locally' do
      expect(sync.client).to receive(:fetch_members).and_return([member(user)])
      expect(subject).to eq([user.email])
    end

    it 'is empty if email exists locally and remotely' do
      mailing_list.subscriptions.create!(subscriber: user)

      expect(sync.client).to receive(:fetch_members).and_return([member(user)])
      expect(subject).to be_empty
    end
  end

  context '#changed_people' do
    subject { sync.changed_people }

    it 'is empty when remote is empty' do
      mailing_list.subscriptions.create!(subscriber: user)
      expect(sync.client).to receive(:fetch_members).and_return([])
      expect(subject).to be_empty
    end

    it 'includes person if has changed a member field' do
      mailing_list.subscriptions.create!(subscriber: user)
      expect(sync.client).to receive(:fetch_members).and_return([member(user)])
      user.update(first_name: 'Topster')
      expect(subject).to eq [user]
    end

    it 'is empty if non member field changes' do
      sync.merge_fields = []
      mailing_list.subscriptions.create!(subscriber: user)
      expect(sync.client).to receive(:fetch_members).and_return([member(user)])
      user.update(gender: 'w')
      expect(subject).to be_empty
    end


    it 'includes person if has changed a merge field' do
      mailing_list.subscriptions.create!(subscriber: user)
      expect(sync.client).to receive(:fetch_members).and_return([member(user)])
      user.update(gender: 'w')
      expect(subject).to eq [user]
    end

    it 'is empty if field is not configured as merge field' do
      sync.merge_fields = []
      mailing_list.subscriptions.create!(subscriber: user)
      expect(sync.client).to receive(:fetch_members).and_return([member(user)])
      user.update(gender: 'w')
      expect(subject).to be_empty
    end
  end


  context '#perform' do
    before do
      sync.merge_fields  = []

      allow(client).to receive(:fetch_merge_fields).and_return([])
      allow(client).to receive(:fetch_segments).and_return([])
      allow(client).to receive(:fetch_members).and_return([])
    end

    def member(person, tags = [])
      client.subscriber_body(person).merge(tags: tags)
    end

    context 'result' do
      subject { sync.result }

      def batch_result(total, finished, errored)
        {
          'total_operations' => total,
          'finished_operations' => finished,
          'errored_operations' => errored
        }
      end

      it 'has result for empty sync' do
        sync.perform
        expect(subject.state).to eq :unchanged
      end

      it 'has result for successful sync' do
        allow(client).to receive(:fetch_members).and_return([member(user)])
        expect(client).to receive(:delete).with([user.email]).and_return(batch_result(1,1,0))
        sync.perform
        expect(subject.state).to eq :success
      end

      it 'has result for partial sync' do
        allow(client).to receive(:fetch_members).and_return([member(user)])
        expect(client).to receive(:delete).with([user.email]).and_return(batch_result(2,1,1))
        sync.perform
        expect(subject.state).to eq :partial
      end

      it 'has result for two operations sync' do
        mailing_list.subscriptions.create!(subscriber: user)
        allow(client).to receive(:fetch_members).and_return([{ email_address: 'other@example.com' }])
        expect(client).to receive(:subscribe).with([user]).and_return(batch_result(1,1,0))
        expect(client).to receive(:delete).with(['other@example.com']).and_return(batch_result(2,1,1))
        sync.perform
        expect(subject.state).to eq :partial
      end
    end

    context 'merge fields' do
      it 'creates missing' do
        allow(sync).to receive(:missing_merge_fields).and_return([merge_field])
        allow(client).to receive(:fetch_merge_fields).and_return([])
        expect(client).to receive(:create_merge_fields).with([merge_field])
        sync.perform
      end
    end

    context 'segments' do
      it 'creates missing' do
        allow(sync).to receive(:missing_segments).and_return(%w(foo bar))
        allow(client).to receive(:fetch_members).and_return([])
        expect(client).to receive(:create_segments).with(%w(foo bar))
        sync.perform
      end

      it 'updates stale' do
        mailing_list.subscriptions.create!(subscriber: user)
        user.update(tag_list: tags)

        allow(client).to receive(:fetch_members).and_return([member(user)])
        expect(client).to receive(:fetch_segments).thrice.and_return(segments(tags))
        expect(client).to receive(:update_segments).with([[0, %w(top_leader@example.com)],
                                                          [1, %w(top_leader@example.com)]])
        sync.perform
      end

      it 'removes obsolete' do
        allow(sync).to receive(:obsolete_segment_ids).and_return(%w(0 1))
        allow(client).to receive(:fetch_members).and_return([])
        expect(client).to receive(:delete_segments).with(%w(0 1))
        sync.perform
      end
    end

    context 'subscriptions' do
      it 'calls operations with empty lists' do
        expect(client).to receive(:subscribe).with([])
        expect(client).to receive(:delete).with([])

        sync.perform
      end

      it 'subscribes missing person' do
        allow(client).to receive(:fetch_members).and_return([])
        mailing_list.subscriptions.create!(subscriber: user)

        expect(client).to receive(:subscribe).with([user])
        expect(client).to receive(:delete).with([])

        sync.perform
      end

      it 'ignores person without email' do
        allow(client).to receive(:fetch_members).and_return([])
        user.update(email: nil)
        mailing_list.subscriptions.create!(subscriber: user)

        expect(client).to receive(:subscribe).with([])
        expect(client).to receive(:delete).with([])

        sync.perform
      end

      it 'updates changed first name' do
        mailing_list.subscriptions.create!(subscriber: user)
        allow(client).to receive(:fetch_members).and_return([member(user)])

        user.update(first_name: 'topster')
        expect(client).to receive(:update_members).with([user])
        sync.perform
      end

      it 'removes obsolete person' do
        allow(client).to receive(:fetch_members).and_return([{ email_address: user.email }])

        expect(client).to receive(:subscribe).with([])
        expect(client).to receive(:delete).with([user.email])

        sync.perform
      end
    end
  end
end
