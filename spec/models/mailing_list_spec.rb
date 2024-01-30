# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: mailing_lists
#
#  id                                  :integer          not null, primary key
#  additional_sender                   :string(255)
#  anyone_may_post                     :boolean          default(FALSE), not null
#  delivery_report                     :boolean          default(FALSE), not null
#  description                         :text(65535)
#  filter_chain                        :text(65535)
#  mail_name                           :string(255)
#  mailchimp_api_key                   :string(255)
#  mailchimp_include_additional_emails :boolean          default(FALSE)
#  mailchimp_last_synced_at            :datetime
#  mailchimp_result                    :text(65535)
#  mailchimp_syncing                   :boolean          default(FALSE)
#  main_email                          :boolean          default(FALSE)
#  name                                :string(255)      not null
#  preferred_labels                    :string(255)
#  publisher                           :string(255)
#  subscribable_for                    :string(255)      default("nobody"), not null
#  subscribable_mode                   :string(255)
#  subscribers_may_post                :boolean          default(FALSE), not null
#  group_id                            :integer          not null
#  mailchimp_list_id                   :string(255)
#
# Indexes
#
#  index_mailing_lists_on_group_id  (group_id)
#

require 'spec_helper'

describe MailingList do

  let(:list)   { Fabricate(:mailing_list, group: groups(:top_layer)) }
  let(:person) { Fabricate(:person) }
  let(:event)  { Fabricate(:event, groups: [list.group], dates: [Fabricate(:event_date, start_at: Time.zone.today)]) }

  describe 'preferred_labels' do
    it 'serializes to empty array if missing' do
      expect(MailingList.new.preferred_labels).to eq []
      expect(mailing_lists(:leaders).preferred_labels).to eq []
    end

    it 'sorts array and removes duplicates' do
      list.update(preferred_labels: %w(foo bar bar baz))
      expect(list.reload.preferred_labels).to eq %w(bar baz foo)
    end

    it 'ignores blank values' do
      list.update(preferred_labels: [''])
      expect(list.reload.preferred_labels).to eq []
    end

    it 'strips whitespaces blank values' do
      list.update(preferred_labels: [' test '])
      expect(list.reload.preferred_labels).to eq ['test']
    end
  end

  describe 'labels' do
    it 'includes main if set' do
      expect(list.labels).to eq []
      list.update(preferred_labels: %w(foo))
      expect(list.reload.labels).to eq %w(foo)
      list.update(main_email: true)
      expect(list.reload.labels).to eq %w(foo _main)
    end
  end

  describe 'validations' do
    it 'succeed with mail_name' do
      list.mail_name = 'aa-b'
      expect(list).to be_valid
    end

    it 'succeed with one char mail_name' do
      list.mail_name = 'a'
      expect(list).to be_valid
    end

    it 'fails with mail_name and invalid chars' do
      list.mail_name = 'a@aa'
      expect(list).to have(1).error_on(:mail_name)
    end

    it 'fails with mail_name and invalid first char' do
      list.mail_name = '-aa'
      expect(list).to have(1).error_on(:mail_name)
    end

    it 'fails with duplicate mail name' do
      Fabricate(:mailing_list, mail_name: 'foo', group: groups(:bottom_layer_one))
      list.mail_name = 'foo'
      expect(list).to have(1).error_on(:mail_name)
    end

    it 'succeed with additional_sender' do
      list.additional_sender = ''
      expect(list).to be_valid
    end
    it 'succeed with additional_sender' do
      list.additional_sender = 'abc@de.ft; *@df.dfd.ee,test@test.test'
      expect(list).to be_valid
    end
    it 'succeed with additional_sender' do
      list.additional_sender = 'abc*dv@test.ch'
      expect(list).to have(1).error_on(:additional_sender)
    end
    it 'succeed with additional_sender' do
      list.additional_sender = 'abc@de.ft;as*d@df.dfd.ee,test@test.test'
      expect(list).to have(1).error_on(:additional_sender)
    end
  end

  it '#subscribed? delegates to MailingLists::Subscribers' do
    create_subscription(person)
    expect_any_instance_of(MailingLists::Subscribers).to receive(:subscribed?)
      .with(person).and_call_original
    expect(list.subscribed?(person)).to be_truthy
  end

  context 'mailchimp' do
    let(:leaders) { mailing_lists(:leaders) }

    it 'does not enqueue destroy job if list is not connected' do
      expect { list.destroy }.not_to change { Delayed::Job.count }
    end

    it 'does enqueue destroy job if list is connected' do
      list.update!(mailchimp_api_key: 1, mailchimp_list_id: 1)
      expect { list.destroy }.to change { Delayed::Job.count }.by(1)
    end
  end

  context 'messages' do
    let(:message) { messages(:simple) }

    it 'delete nullifies mailing_list on message' do
      expect(message.mailing_list.destroy).to be_truthy
      expect(message.reload.mailing_list).to be_nil
    end
  end

  describe 'subscribable for and subscribable_mode' do
    let(:leaders) { mailing_lists(:leaders) }

    context 'subscribable_for is configured' do
      before { leaders.subscribable_for = 'configured' }

      it 'sets default subscribable mode if none is set' do
        expect(leaders).to be_valid
        expect(leaders.subscribable_mode).to eq 'opt_out'
      end

      it 'accepts any valid subscribable mode' do
        leaders.subscribable_mode = 'opt_in'
        expect(leaders).to be_valid
        expect(leaders.subscribable_mode).to eq 'opt_in'
      end

      it 'rejects invalid subscribable mode' do
        leaders.subscribable_mode = 'invalid'
        expect(leaders).not_to be_valid
      end
    end

    it 'keeps mode when anyone may subscribe' do
      leaders.subscribable_mode = 'opt_in'
      expect(leaders).to be_valid
      expect(leaders.subscribable_mode).to eq 'opt_in'
    end

    it 'resets mode when not subscribable' do
      leaders.subscribable_for = 'nobody'
      leaders.subscribable_mode = 'opt_in'
      expect(leaders).to be_valid
      expect(leaders.subscribable_mode).to be_blank
    end

    describe 'job scheduling' do
      it 'schedules cleanup job if subscribable_for is configured' do
        expect do
          leaders.update!(subscribable_mode: :opt_in)
        end.to change { Delayed::Job.count }.by(1)
      end

      it 'does not schedule job on other attr changes' do
        leaders.update!(subscribable_mode: :opt_in)
        expect do
          leaders.update!(subscribable_for: :configured)
        end.not_to change { Delayed::Job.count }
      end
    end
  end

  describe '::subscribable' do
    let(:leaders) { mailing_lists(:leaders) }

    it 'includes leaders as subscriable_for is configured as anyone' do
      expect(MailingList.subscribable).to include(leaders)
    end

    it 'includes leaders if subscriable_for is configured as configured' do
      leaders.update!(subscribable_for: :configured)
      expect(MailingList.subscribable).to include(leaders)
    end

    it 'excludes leaders if subscriable_for is configured as nobody' do
      leaders.update!(subscribable_for: :nobody)
      expect(MailingList.subscribable).not_to include(leaders)
    end
  end

  private

  def create_subscription(subscriber, excluded = false, *role_types)
    sub = list.subscriptions.new
    sub.subscriber = subscriber
    sub.excluded = excluded
    sub.related_role_types = role_types.collect { |t| RelatedRoleType.new(role_type: t) }
    sub.save!
    sub
  end

  def subscription_tags(names)
    tags = names.map { |name| ActsAsTaggableOn::Tag.create_or_find_by!(name: name) }
    tags.map { |tag| SubscriptionTag.new(tag: tag) }
  end
end
