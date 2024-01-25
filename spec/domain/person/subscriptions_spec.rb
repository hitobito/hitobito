# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::Subscriptions do

  let(:leaders)   { mailing_lists(:leaders) }
  let(:person)    { people(:top_leader) }

  let(:top_layer) { groups(:top_layer) }
  let(:top_group) { groups(:top_group) }

  def create_group_subscription(list = leaders)
    list.subscriptions.create!(subscriber: top_group,
                               role_types: ['Group::TopGroup::Leader'])
  end

  def create_event_subscription(list = leaders)
    event = Fabricate(:event, groups: [top_layer])
    event.participations.create!(person: person, active: true)
    event.reload.dates.first.update!(start_at: 10.days.ago)
    list.subscriptions.create!(subscriber: event)
  end

  context 'subscribable_for anyone' do
    before { leaders.update(subscribable_for: :anyone) }

    describe '#subscribed' do
      subject(:subscribed) { described_class.new(person).subscribed }

      it 'is empty without subscription' do
        expect(subscribed).to be_empty
      end

      it 'includes leaders when direct subscription exists' do
        leaders.subscriptions.create!(subscriber: person)
        expect(subscribed).to eq [leaders]
      end

      it 'includes leaders when group subscription exists' do
        create_group_subscription
        expect(subscribed).to eq [leaders]
      end

      it 'includes leaders when event subscription exists' do
        create_event_subscription
        expect(subscribed).to eq [leaders]
      end

      it 'excludes leaders when group subscriptions exists but excluded' do
        create_group_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribed).to be_empty
      end

      it 'excludes leaders when event subscriptions exists but excluded' do
        create_event_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribed).to be_empty
      end
    end

    describe '#subscribable' do
      subject(:subscribable) { described_class.new(person).subscribable }
      before { MailingList.where.not(id: leaders.id).destroy_all }

      it 'includes leaders when no subscription exists' do
        expect(subscribable).to eq [leaders]
      end

      it 'excludes leaders when direct subscription exists' do
        leaders.subscriptions.create!(subscriber: person)
        expect(subscribable).to be_empty
      end

      it 'excludes leaders when group subscription exists' do
        create_group_subscription
        expect(subscribable).to be_empty
      end

      it 'excludes leaders when event subscription exists' do
        create_event_subscription
        expect(subscribable).to be_empty
      end

      it 'includes leaders when group subscriptions exists but excluded' do
        create_group_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribable).to eq [leaders]
      end

      it 'includes leaders when event subscriptions exists but excluded' do
        create_event_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribable).to eq [leaders]
      end
    end
  end

  context 'subscribable_for configured with mode opt_out' do
    before { leaders.update(subscribable_for: :configured, subscribable_mode: :opt_out) }

    describe '#subscribed' do
      subject(:subscribed) { described_class.new(person).subscribed }

      it 'is empty without subscription' do
        expect(subscribed).to be_empty
      end

      it 'includes leaders when direct subscription exists' do
        leaders.subscriptions.create!(subscriber: person)
        expect(subscribed).to eq [leaders]
      end

      it 'includes leaders when group subscription exists' do
        create_group_subscription
        expect(subscribed).to eq [leaders]
      end

      it 'includes leaders when event subscription exists' do
        create_event_subscription
        expect(subscribed).to eq [leaders]
      end

      it 'excludes leaders when group subscriptions exists but excluded' do
        create_group_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribed).to be_empty
      end

      it 'excludes leaders when event subscriptions exists but excluded' do
        create_event_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribed).to be_empty
      end
    end

    describe '#subscribable' do
      subject(:subscribable) { described_class.new(person).subscribable }
      before { MailingList.where.not(id: leaders.id).destroy_all }

      it 'excludes leaders when no subscription exists' do
        expect(subscribable).to be_empty
      end

      it 'excludes leaders when direct subscription exists' do
        leaders.subscriptions.create!(subscriber: person)
        expect(subscribable).to be_empty
      end

      it 'excludes leaders when group subscription exists' do
        create_group_subscription
        expect(subscribable).to be_empty
      end

      it 'excludes leaders when event subscription exists' do
        create_event_subscription
        expect(subscribable).to be_empty
      end

      it 'includes leaders when group subscriptions exists but excluded' do
        create_group_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribable).to eq [leaders]
      end

      it 'includes leaders when event subscriptions exists but excluded' do
        create_event_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribable).to eq [leaders]
      end
    end
  end

  context 'subscribable_for configured with mode opt_in' do
    before { leaders.update(subscribable_for: :configured, subscribable_mode: :opt_in) }

    describe '#subscribed' do
      subject(:subscribed) { described_class.new(person).subscribed }

      it 'is empty without subscription' do
        expect(subscribed).to be_empty
      end

      it 'includes leaders when direct subscription exists' do
        leaders.subscriptions.create!(subscriber: person)
        expect(subscribed).to eq [leaders]
      end

      it 'excludes leaders when group subscription exists' do
        create_group_subscription
        expect(subscribed).to be_empty
      end

      it 'excludes leaders when event subscription exists' do
        create_event_subscription
        expect(subscribed).to be_empty
      end

      it 'excludes leaders when group subscriptions exists but excluded' do
        create_group_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribed).to be_empty
      end

      it 'excludes leaders when event subscriptions exists but excluded' do
        create_event_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribed).to be_empty
      end
    end

    describe '#subscribable' do
      subject(:subscribable) { described_class.new(person).subscribable }
      before { MailingList.where.not(id: leaders.id).destroy_all }

      it 'excludes leaders when no subscription exists' do
        expect(subscribable).to be_empty
      end

      it 'excludes leaders when direct subscription exists' do
        leaders.subscriptions.create!(subscriber: person)
        expect(subscribable).to be_empty
      end

      it 'includes leaders when group subscription exists' do
        create_group_subscription
        expect(subscribable).to eq [leaders]
      end

      it 'includes leaders when event subscription exists' do
        create_event_subscription
        expect(subscribable).to eq [leaders]
      end

      it 'includes leaders when group subscriptions exists but excluded' do
        create_group_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribable).to eq [leaders]
      end

      it 'includes leaders when event subscriptions exists but excluded' do
        create_event_subscription
        leaders.subscriptions.create!(subscriber: person, excluded: true)
        expect(subscribable).to eq [leaders]
      end
    end
  end


  context :mailing_lists do
    subject { Person::Subscriptions.new(person).subscribed }

    let!(:direct) do
      Fabricate(:mailing_list, subscribable_for: :anyone, group: top_layer).tap do |list|
        list.subscriptions.create!(subscriber: person)
      end
    end

    let!(:from_event) do
      Fabricate(:mailing_list, subscribable_for: :anyone, group: top_layer).tap do |list|
        create_event_subscription(list)
      end
    end

    let!(:from_group) do
      Fabricate(:mailing_list, subscribable_for: :anyone, group: top_layer).tap do |list|
        create_group_subscription(list)
        list.subscriptions.create!(subscriber: top_group, role_types: ['Group::TopGroup::Leader'])
      end
    end

    it 'includes all three mailing lists' do
      expect(subject).to match_array [direct, from_event, from_group]
    end

    it 'does not include group if person is excluded' do
      from_group.subscriptions.create!(subscriber: person, excluded: true)
      expect(subject).to match_array [direct, from_event]
    end
  end

  context :direct do
    subject { Person::Subscriptions.new(person).direct }

    it 'includes direct subscriptions' do
      leaders.subscriptions.create!(subscriber: person)
      expect(subject).to have(1).item
    end

    it 'does not includes direct subscriptions where excluded is true' do
      leaders.subscriptions.create!(subscriber: person, excluded: true)
      expect(subject).to be_empty
    end
  end

  context :exclusions do
    subject { Person::Subscriptions.new(person).exclusions }

    it 'includes direct subscriptions' do
      leaders.subscriptions.create!(subscriber: person)
      expect(subject).to be_empty
    end

    it 'does not includes direct subscriptions where excluded is true' do
      leaders.subscriptions.create!(subscriber: person, excluded: true)
      expect(subject).to have(1).item
    end
  end

  context :from_events do
    let(:person)        { people(:bottom_member) }
    let(:event)         { events(:top_course) }
    let(:participation) { event_participations(:top) }

    subject { Person::Subscriptions.new(person).from_events }

    before do
      event.dates.first.update(start_at: 10.days.ago)
      leaders.subscriptions.create(subscriber: event)
    end

    it 'includes subscription for active participation' do
      expect(subject).to be_present
    end

    it 'does not include subscription for passive participation' do
      participation.update!(active: false)
      expect(subject).to be_empty
    end
  end

  context :from_groups do
    let(:person)       { people(:bottom_member) }
    let(:subscription) { subscriptions(:leaders_group) }

    let(:bottom_layer_one) { groups(:bottom_layer_one) }
    let(:bottom_layer_two) { groups(:bottom_layer_two) }

    subject { Person::Subscriptions.new(person).from_groups }

    it 'is present when created for group' do
      leaders.subscriptions.create!(subscriber: bottom_layer_one,
                                    role_types: ['Group::BottomLayer::Member'])
      expect(subject).to have(1).item
    end

    it 'is present when created for ancestor group' do
      leaders.subscriptions.create!(subscriber: top_layer,
                                    role_types: ['Group::BottomLayer::Member'])
      expect(subject).to have(1).item
    end

    it 'is empty when created for sibling group' do
      leaders.subscriptions.create!(subscriber: bottom_layer_two,
                                    role_types: ['Group::BottomLayer::Member'])
      expect(subject).to be_empty
    end

    it 'is empty when tag required' do
      subscription_tag = SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create!(name: 'foo'))
      leaders.subscriptions.create!(subscriber: bottom_layer_one,
                                    role_types: ['Group::BottomLayer::Member'], subscription_tags: [subscription_tag])
      expect(subject).to be_empty
    end

    it 'is present when tag is required and any person matches and tag does not exclude' do
      subscription_tag = SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create!(name: 'foo'),
                                             excluded: false)
      leaders.subscriptions.create!(subscriber: bottom_layer_one,
                                    role_types: ['Group::BottomLayer::Member'], subscription_tags: [subscription_tag])
      person.update!(tag_list: %w(foo buz))
      expect(subject).to have(1).item
    end

    it 'is empty when tag is required and any person matches and tag does exclude' do
      subscription_tag = SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create!(name: 'foo'),
                                             excluded: true)
      subscription_tag2 = SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create!(name: 'bar'),
                                              excluded: false)
      leaders.subscriptions.create!(subscriber: bottom_layer_one,
                                    role_types: ['Group::BottomLayer::Member'], subscription_tags: [subscription_tag, subscription_tag2])
      person.update!(tag_list: %w(foo bar))
      expect(subject).to be_empty
    end

    it 'is empty when the person has no roles' do
      leaders.subscriptions.create!(subscriber: bottom_layer_one,
                                    role_types: ['Group::BottomLayer::Member'])
      person.roles.destroy_all
      expect(subject).to be_empty
    end

  end

end
