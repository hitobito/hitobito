#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"
require "digest/md5"

describe Synchronize::Mailchimp::Synchronizator do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:mailing_list) { mailing_lists(:leaders) }
  let(:with_default_tag) { false }
  let(:sync) { Synchronize::Mailchimp::Synchronizator.new(mailing_list, with_default_tag: with_default_tag) }
  let(:client) { sync.send(:client) }

  let(:tags) { %w[foo bar] }
  let(:merge_field) {
    ["Gender", "dropdown", {choices: %w[m w]}, ->(p) { person.gender }]
  }

  def batch_result(total, finished, errored, operation_results = [])
    [
      {},
      {
        total_operations: total,
        finished_operations: finished,
        errored_operations: errored,
        operation_results: operation_results
      }
    ]
  end

  def segments(names)
    names.collect.each_with_index do |name, index|
      {id: index, name: name, member_count: 0}
    end
  end

  def member(person, tags = [], status: "subscribed")
    client.subscriber_body(person).merge(tags: tags)
  end

  context "#missing_merge_fields" do
    before { sync.merge_fields = [] }

    subject(:missing_merge_fields) { sync.send(:missing_merge_fields) }

    it "is empty when no merge_fields is empty" do
      allow(client).to receive(:fetch_merge_fields).and_return([])
      expect(missing_merge_fields).to be_empty
    end

    it "includes local merge_field that does not exist remotely" do
      sync.merge_fields = [merge_field]
      allow(client).to receive(:fetch_merge_fields).and_return([])
      expect(missing_merge_fields).to eq [merge_field]
    end

    it "is empty when merge_field exists locally and remotely" do
      sync.merge_fields = [merge_field]
      allow(client).to receive(:fetch_merge_fields).and_return([{tag: "GENDER"}])
      expect(missing_merge_fields).to be_empty
    end
  end

  context "#missing_segments" do
    subject(:missing_segments) { sync.send(:missing_segments) }

    it "is empty when subscribers have no tags" do
      allow(client).to receive(:fetch_segments).and_return([])
      mailing_list.subscriptions.create!(subscriber: top_leader)
      expect(missing_segments).to be_empty
    end

    it "is empty when subscribers have only technical tags" do
      Contactable::InvalidEmailTagger.new(top_leader, top_leader.email, :primary).tag!
      Contactable::InvalidEmailTagger.new(top_leader, top_leader.email, :additional).tag!

      allow(client).to receive(:fetch_segments).and_return([])
      mailing_list.subscriptions.create!(subscriber: top_leader)
      expect(missing_segments).to be_empty
    end

    it "is includes local tag if it does not exist remotely" do
      allow(client).to receive(:fetch_segments).and_return([])
      mailing_list.subscriptions.create!(subscriber: top_leader)
      top_leader.update(tag_list: %w[foo])
      expect(missing_segments).to eq %w[foo]
    end

    it "is includes bottom_member local tag if it does not exist remotely" do
      allow(client).to receive(:fetch_segments).and_return([])
      mailing_list.subscriptions.create!(subscriber: top_leader)
      top_leader.update(tag_list: %w[foo bar])
      allow(client).to receive(:fetch_segments).and_return(segments(%w[foo]))
      expect(missing_segments).to eq %w[bar]
    end

    it "is empty if both tags exists remotely" do
      allow(client).to receive(:fetch_segments).and_return(segments(%w[foo bar]))
      mailing_list.subscriptions.create!(subscriber: top_leader)
      top_leader.update(tag_list: %w[foo bar])
      expect(missing_segments).to be_empty
    end
  end

  context "#obsolete_segment_ids" do
    subject(:obsolete_segment_ids) { sync.send(:obsolete_segment_ids) }

    it "is empty when no remote segments exist" do
      allow(client).to receive(:fetch_segments).and_return([])
      expect(obsolete_segment_ids).to be_empty
    end

    it "is present if no local tag exists for remote segment" do
      allow(client).to receive(:fetch_segments).and_return(segments(%w[foo]))
      expect(obsolete_segment_ids).to eq [0]
    end

    it "is empty if local tag exists remotely" do
      allow(client).to receive(:fetch_segments).and_return(segments(%w[foo]))
      mailing_list.subscriptions.create!(subscriber: top_leader)
      top_leader.update(tag_list: %w[foo])
      expect(obsolete_segment_ids).to be_empty
    end
  end

  context "#stale_segments" do
    subject(:stale_segments) { sync.send(:stale_segments) }

    let(:root) { people(:root) }

    it "is empty when no tags are defined" do
      mailing_list.subscriptions.create!(subscriber: top_leader)
      expect(client).to receive(:fetch_segments).and_return([])
      expect(stale_segments).to eq []
    end

    it "is empty when we have only local tags" do
      top_leader.update(tag_list: tags)
      mailing_list.subscriptions.create!(subscriber: top_leader)

      expect(client).to receive(:fetch_members).and_return([])
      expect(client).to receive(:fetch_segments).and_return([])
      expect(stale_segments).to eq []
    end

    it "contains diff when remote has stale tag" do
      mailing_list.subscriptions.create!(subscriber: top_leader)
      mailing_list.subscriptions.create!(subscriber: bottom_member)
      top_leader.update(tag_list: tags)
      bottom_member.update(tag_list: tags.take(1))

      expect(client).to receive(:fetch_members).and_return([
        member(top_leader, segments(tags)),
        member(bottom_member, segments(tags))
      ])
      expect(client).to receive(:fetch_segments).and_return(segments(tags))
      expect(stale_segments.first).to eq([1, members_to_add: [], members_to_remove: %w[bottom_member@example.com]])
    end

    it "batches tag members_to add" do
      stub_const("Synchronize::Mailchimp::SegmentUpdate::SLICE_SIZE", 2)
      mailing_list.subscriptions.create!(subscriber: top_leader)
      mailing_list.subscriptions.create!(subscriber: bottom_member)
      mailing_list.subscriptions.create!(subscriber: root)

      top_leader.update(tag_list: tags)
      bottom_member.update(tag_list: tags.take(1))
      root.update(tag_list: tags.take(1))

      expect(client).to receive(:fetch_members).and_return([
        member(top_leader),
        member(bottom_member),
        member(root)
      ])
      expect(client).to receive(:fetch_segments).and_return(segments(tags))
      expect(stale_segments).to eq([
        [0, {members_to_add: ["bottom_member@example.com", "pushkar@vibha.org"], members_to_remove: []}],
        [0, {members_to_add: ["top_leader@example.com"], members_to_remove: []}],
        [1, {members_to_add: ["top_leader@example.com"], members_to_remove: []}]
      ])
    end

    it "contains diff when local has extra tags" do
      mailing_list.subscriptions.create!(subscriber: top_leader)
      mailing_list.subscriptions.create!(subscriber: bottom_member)
      top_leader.update(tag_list: tags)
      bottom_member.update(tag_list: tags)

      expect(client).to receive(:fetch_members).and_return([
        member(top_leader, segments(tags).take(1)),
        member(bottom_member, segments(tags).take(1))
      ])
      expect(client).to receive(:fetch_segments).and_return(segments(tags))
      expect(stale_segments).to have(1).item
      expect(stale_segments.first).to eq([1, members_to_add: %w[bottom_member@example.com top_leader@example.com], members_to_remove: []])
    end

    it "is empty when all local tags exist remotely" do
      top_leader.update(tag_list: tags)
      mailing_list.subscriptions.create!(subscriber: top_leader)

      expect(client).to receive(:fetch_members).and_return([member(top_leader, segments(tags))])
      expect(client).to receive(:fetch_segments).and_return(segments(tags))
      expect(stale_segments).to eq([])
    end

    it "is empty when all local tags exist remotely" do
      top_leader.update(tag_list: tags)
      mailing_list.subscriptions.create!(subscriber: top_leader)

      expect(client).to receive(:fetch_members).and_return([])
      expect(client).to receive(:fetch_segments).and_return([])

      expect(stale_segments).to eq([])
    end

    context "with_default_tag" do
      let(:with_default_tag) { true }

      it "does not fail on nil email" do
        top_leader.update(email: nil)
        mailing_list.subscriptions.create!(subscriber: top_leader)
        mailing_list.subscriptions.create!(subscriber: Fabricate(:person))

        expect(client).to receive(:fetch_members).and_return([])
        expect(client).to receive(:fetch_segments).and_return([]).twice
        expect(stale_segments).to eq([])
      end
    end
  end

  context "#missing_subscribers" do
    subject(:missing_people) { sync.send(:missing_subscribers).map(&:person) }

    it "is empty without subscriptions" do
      expect(missing_people).to be_empty
    end

    it "includes subscribers email if it does not exist remotely" do
      mailing_list.subscriptions.create!(subscriber: top_leader)

      expect(client).to receive(:fetch_members).and_return([])
      expect(missing_people).to eq([top_leader])
    end

    it "is empty if email does exist remotely" do
      mailing_list.subscriptions.create!(subscriber: top_leader)

      expect(client).to receive(:fetch_members).and_return([member(top_leader)])
      expect(missing_people).to be_empty
    end
  end

  context "#obsolete_emails" do
    subject(:obsolete_emails) { sync.send(:obsolete_emails) }

    it "is empty when remote is empty" do
      expect(client).to receive(:fetch_members).and_return([])
      expect(obsolete_emails).to be_empty
    end

    it "includes email if remote email does not exist locally" do
      expect(client).to receive(:fetch_members).and_return([member(top_leader)])
      expect(obsolete_emails).to eq([top_leader.email])
    end

    it "is empty if remote email does not exist locally but is cleaned" do
      expect(client).to receive(:fetch_members).and_return([member(top_leader), status: "cleaned"])
      expect(obsolete_emails).to eq([top_leader.email])
    end

    it "is empty if email exists locally and remotely" do
      mailing_list.subscriptions.create!(subscriber: top_leader)

      expect(client).to receive(:fetch_members).and_return([member(top_leader)])
      expect(obsolete_emails).to be_empty
    end
  end

  context "#changed_subscribers" do
    subject(:changed_people) { sync.send(:changed_subscribers).map(&:person) }

    it "is empty when remote is empty" do
      mailing_list.subscriptions.create!(subscriber: top_leader)
      expect(client).to receive(:fetch_members).and_return([])
      expect(changed_people).to be_empty
    end

    it "includes person if has changed a member field" do
      mailing_list.subscriptions.create!(subscriber: top_leader)
      expect(client).to receive(:fetch_members).and_return([member(top_leader)])
      top_leader.update(first_name: "Topster")
      expect(changed_people).to eq [top_leader]
    end

    it "is empty if non member field changes" do
      sync.merge_fields = []
      mailing_list.subscriptions.create!(subscriber: top_leader)
      expect(client).to receive(:fetch_members).and_return([member(top_leader)])
      top_leader.update(gender: "w")
      expect(changed_people).to be_empty
    end

    it "includes person if has changed a merge field" do
      mailing_list.subscriptions.create!(subscriber: top_leader)
      expect(client).to receive(:fetch_members).and_return([member(top_leader)])
      top_leader.update(gender: "w")
      expect(changed_people).to eq [top_leader]
    end

    it "is empty if field is not configured as merge field" do
      sync.merge_fields = []
      mailing_list.subscriptions.create!(subscriber: top_leader)
      expect(client).to receive(:fetch_members).and_return([member(top_leader)])
      top_leader.update(gender: "w")
      expect(changed_people).to be_empty
    end
  end

  context "#perform" do
    before do
      sync.merge_fields = []

      allow(client).to receive(:fetch_merge_fields).and_return([])
      allow(client).to receive(:fetch_segments).and_return([])
      allow(client).to receive(:fetch_members).and_return([])
    end

    def member(person, tags = [])
      client.subscriber_body(person).merge(tags: tags)
    end

    context "result" do
      subject(:result) { sync.result }

      it "has result for empty sync" do
        sync.perform
        expect(subject.state).to eq :unchanged
      end

      it "has result for successful sync" do
        allow(client).to receive(:fetch_members).and_return([member(top_leader)])
        expect(client).to receive(:unsubscribe_members).with([top_leader.email]).and_return(batch_result(1, 1, 0))
        sync.perform
        expect(result.state).to eq :success
      end

      it "has result for partial sync" do
        allow(client).to receive(:fetch_members).and_return([member(top_leader)])
        expect(client).to receive(:unsubscribe_members).with([top_leader.email]).and_return(batch_result(2, 1, 1))
        sync.perform
        expect(result.state).to eq :partial
      end

      it "has result for two operations sync" do
        mailing_list.subscriptions.create!(subscriber: top_leader)
        allow(client).to receive(:fetch_members).and_return([{email_address: "bottom_member@example.com"}])
        expect(client).to receive(:subscribe_members) { |subscribers|
          expect(subscribers.map(&:person)).to eq([top_leader])
        }.and_return(batch_result(1, 1, 0))
        expect(client).to receive(:unsubscribe_members).with(["bottom_member@example.com"]).and_return(batch_result(2, 1, 1))
        sync.perform
        expect(result.state).to eq :partial
      end
    end

    context "merge fields" do
      it "creates missing" do
        allow(sync).to receive(:missing_merge_fields).and_return([merge_field])
        allow(client).to receive(:fetch_merge_fields).and_return([])
        expect(client).to receive(:create_merge_fields).with([merge_field])
        sync.perform
      end
    end

    context "segments" do
      it "creates missing" do
        allow(sync).to receive(:missing_segments).and_return(%w[foo bar])
        allow(client).to receive(:fetch_members).and_return([])
        expect(client).to receive(:create_segments).with(%w[foo bar])
        sync.perform
      end

      it "updates stale" do
        mailing_list.subscriptions.create!(subscriber: top_leader)
        top_leader.update(tag_list: tags)

        allow(client).to receive(:fetch_members).and_return([member(top_leader)])
        expect(client).to receive(:fetch_segments).thrice.and_return(segments(tags))
        expect(client).to receive(:update_segments).with([
          [0, {members_to_add: ["top_leader@example.com"], members_to_remove: []}],
          [1, {members_to_add: ["top_leader@example.com"], members_to_remove: []}]
        ])
        sync.perform
      end

      it "removes obsolete" do
        allow(sync).to receive(:obsolete_segment_ids).and_return(%w[0 1])
        allow(client).to receive(:fetch_members).and_return([])
        expect(client).to receive(:delete_segments).with(%w[0 1])
        sync.perform
      end
    end

    context "subscriptions" do
      it "calls operations with empty lists" do
        expect(client).to receive(:subscribe_members).with([])
        expect(client).to receive(:unsubscribe_members).with([])

        sync.perform
      end

      it "subscribes missing person" do
        allow(client).to receive(:fetch_members).and_return([])
        mailing_list.subscriptions.create!(subscriber: top_leader)

        expect(client).to receive(:subscribe_members) { |subscribers|
          expect(subscribers.map(&:person)).to eq([top_leader])
        }.and_return(batch_result(1, 1, 0))
        expect(client).to receive(:unsubscribe_members).with([])

        sync.perform
      end

      it "ignores person without email" do
        allow(client).to receive(:fetch_members).and_return([])
        top_leader.update(email: nil)
        mailing_list.subscriptions.create!(subscriber: top_leader)

        expect(client).to receive(:subscribe_members).with([])
        expect(client).to receive(:unsubscribe_members).with([])

        sync.perform
      end

      it "updates changed first name" do
        mailing_list.subscriptions.create!(subscriber: top_leader)
        allow(client).to receive(:fetch_members).and_return([member(top_leader)])

        top_leader.update(first_name: "topster")
        expect(client).to receive(:update_members) { |subscribers|
          expect(subscribers.map(&:person)).to eq([top_leader])
        }.and_return(batch_result(1, 1, 0))
        sync.perform
      end

      it "removes obsolete person" do
        allow(client).to receive(:fetch_members).and_return([{email_address: top_leader.email}])

        expect(client).to receive(:subscribe_members).with([])
        expect(client).to receive(:unsubscribe_members).with([top_leader.email])

        sync.perform
      end

      it "ignores obsolete person when email is cleaned" do
        allow(client).to receive(:fetch_members).and_return([{email_address: top_leader.email, status: "cleaned"}])

        expect(client).to receive(:subscribe_members).with([])
        expect(client).to receive(:unsubscribe_members).with([])

        sync.perform
      end

      describe "permanently deleted emails" do
        before {
          mailing_list.subscriptions.create!(subscriber: top_leader)
          allow(client).to receive(:fetch_members).and_return([])
        }

        it "updates single email" do
          expect(client).to receive(:subscribe_members) { |subscribers|
            expect(subscribers.map(&:person)).to eq([top_leader])
          }.and_return(batch_result(1, 0, 1, [detail: "#{top_leader.email} was permanently deleted"]))
          sync.perform
          expect(mailing_list.reload.mailchimp_forgotten_emails).to eq [top_leader.email]
        end

        it "appends to existing emails" do
          mailing_list.update!(mailchimp_forgotten_emails: %w[foo@example.com bar@example.com])
          expect(client).to receive(:subscribe_members) { |subscribers|
            expect(subscribers.map(&:person)).to eq([top_leader])
          }.and_return(batch_result(1, 0, 1, [detail: "#{top_leader.email} was permanently deleted"]))
          sync.perform
          expect(mailing_list.reload.mailchimp_forgotten_emails).to match_array %W[foo@example.com bar@example.com #{top_leader.email}]
        end

        it "ignores forgotten_emails when syncing" do
          mailing_list.update!(mailchimp_forgotten_emails: [top_leader.email])
          expect(client).to receive(:subscribe_members).with([])
          sync.perform
          expect(mailing_list.reload.mailchimp_forgotten_emails).to eq [top_leader.email]
        end
      end
    end

    context "tag_cleaned_members" do
      it "creates invalid email tag on person" do
        allow(client).to receive(:fetch_members).and_return([{email_address: top_leader.email, status: "cleaned"}])

        expect(client).to receive(:update_members)
        expect(client).to receive(:subscribe_members).with([])
        expect(client).to receive(:unsubscribe_members).with([])

        Subscription.create!(mailing_list: mailing_list, subscriber: top_leader)
        sync.perform
        expect(top_leader).to have(1).tag
      end
    end
  end

  context "with default tag" do
    let(:sync) { Synchronize::Mailchimp::Synchronizator.new(mailing_list) }
    let(:default_tag) { "hitobito-mailing-list-#{mailing_list.id}" }

    before do
      sync.merge_fields = []

      allow(client).to receive(:fetch_merge_fields).and_return([])
    end

    it "creates default segment" do
      allow(client).to receive(:fetch_segments).and_return([])
      allow(client).to receive(:fetch_members).and_return([])
      expect(client).to receive(:create_segments).with([default_tag])
      sync.perform
    end

    it "creates default segment and adds new subscriber to default segment" do
      mailing_list.subscriptions.create!(subscriber: top_leader)

      allow(client).to receive(:fetch_segments).and_return([], segments([default_tag]))
      allow(client).to receive(:fetch_members).and_return([])
      expect(client).to receive(:create_segments).with([default_tag])
      expect(client).to receive(:subscribe_members).with([kind_of(Synchronize::Mailchimp::Subscriber)])
      expect(client).to receive(:update_segments).with([
        [0, {members_to_add: ["top_leader@example.com"], members_to_remove: []}]
      ])
      sync.perform
    end

    it "creates default segment and adds existing subscriber to default segmnet" do
      mailing_list.subscriptions.create!(subscriber: top_leader)

      allow(client).to receive(:fetch_segments).and_return([], segments([default_tag]))
      allow(client).to receive(:fetch_members).and_return([member(top_leader)])
      expect(client).to receive(:create_segments).with([default_tag])
      expect(client).to receive(:update_segments).with([
        [0, {members_to_add: ["top_leader@example.com"], members_to_remove: []}]
      ])
      sync.perform
    end

    it "adds existing subscriber to default segment keeping bottom_member tags" do
      mailing_list.subscriptions.create!(subscriber: top_leader)
      top_leader.update(tag_list: tags)
      allow(client).to receive(:fetch_segments).and_return(segments(tags))
      allow(client).to receive(:fetch_members).and_return([member(top_leader, segments(tags).drop(1))])
      expect(client).to receive(:create_segments).with([default_tag])
      expect(client).to receive(:update_segments).with([
        [0, {members_to_add: ["top_leader@example.com"], members_to_remove: []}]
      ])
      sync.perform
    end

    it "ignores forgotten email" do
      mailing_list.update!(mailchimp_include_additional_emails: true, mailchimp_forgotten_emails: %w[forgotten@example.com])
      mailing_list.subscriptions.create!(subscriber: top_leader)
      top_leader.additional_emails.create!(email: "forgotten@example.com", mailings: true, label: "test")
      allow(client).to receive(:fetch_segments).and_return(segments([default_tag]))
      allow(client).to receive(:fetch_members).and_return([member(top_leader, segments([default_tag]))])
      sync.perform
    end

    it "does not update segment when unsubscribing member" do
      allow(client).to receive(:fetch_segments).and_return(segments([default_tag]))
      allow(client).to receive(:fetch_members).and_return([member(top_leader, segments([default_tag]))])
      expect(client).to receive(:unsubscribe_members).with([top_leader.email])
      expect(client).to receive(:update_segments).with([])
      sync.perform
    end

    it "ignores email not part of default segment on initial sync" do
      allow(client).to receive(:fetch_segments).and_return(segments([]), segments([default_tag]))
      allow(client).to receive(:fetch_members).and_return([member(top_leader)])
      expect(client).to receive(:create_segments).with([default_tag])
      sync.perform
    end

    it "ignores email not part of default segment" do
      allow(client).to receive(:fetch_segments).and_return(segments([default_tag]))
      allow(client).to receive(:fetch_members).and_return([member(top_leader)])
      sync.perform
    end
  end
end
