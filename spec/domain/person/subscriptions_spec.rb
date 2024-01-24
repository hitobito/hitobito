require 'spec_helper'


describe Person::Subscriptions do

  let(:leaders)   { mailing_lists(:leaders) }
  let(:person)    { people(:top_leader) }

  let(:top_layer) { groups(:top_layer) }
  let(:top_group) { groups(:top_group) }
  let(:scope) { MailingList.where(id: leaders.id) }

  describe '#subscribable' do
    subject(:list) { described_class.new(person).subscribable }

    it 'includes all 3 lists' do
      expect(list).to have(3).items
    end

    it 'excludes all 3 lists if configured for nobody' do
      MailingList.update_all(subscribable_for: :nobody)
      expect(list).to be_empty
    end

    it 'excludes all 3 lists if configured for configured' do
      MailingList.update_all(subscribable_for: :configured)
      expect(list).to be_empty
    end

    context 'with configured list' do
      let(:leaders) { mailing_lists(:leaders) }

      before do
        MailingList.update_all(subscribable_for: :nobody)
        leaders.update!(subscribable_for: :configured, subscribable_mode: :opt_in)
      end

      it 'includes list if group subscription matches' do
        leaders.subscriptions.create!(subscriber: top_group,
                                      role_types: ['Group::TopGroup::Leader'])

        expect(list).to include(leaders)
      end

      it 'includes list if event subscription matches' do
        event = Fabricate(:event, groups: [top_layer])
        event.participations.create!(person: person, active: true)
        event.reload.dates.first.update!(start_at: 10.days.ago)
        leaders.subscriptions.create!(subscriber: event)

        expect(list).to include(leaders)
      end
    end
  end

  context :mailing_lists do
    subject { Person::Subscriptions.new(person).mailing_lists }

    let!(:direct) do
      Fabricate(:mailing_list, group: top_layer).tap do |list|
        list.subscriptions.create!(subscriber: person)
      end
    end

    let!(:from_event) do
      Fabricate(:mailing_list, group: top_layer).tap do |list|
        event = Fabricate(:event, groups: [top_layer])
        event.participations.create!(person: person, active: true)
        event.reload.dates.first.update!(start_at: 10.days.ago)
        list.subscriptions.create!(subscriber: event)
      end
    end

    let!(:from_group) do
      Fabricate(:mailing_list, group: top_layer).tap do |list|
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
      list.subscriptions.create!(subscriber: person)
      expect(subject).to have(1).item
    end

    it 'does not includes direct subscriptions where excluded is true' do
      list.subscriptions.create!(subscriber: person, excluded: true)
      expect(subject).to be_empty
    end
  end

  context :exclusions do
    subject { Person::Subscriptions.new(person).exclusions }

    it 'includes direct subscriptions' do
      list.subscriptions.create!(subscriber: person)
      expect(subject).to be_empty
    end

    it 'does not includes direct subscriptions where excluded is true' do
      list.subscriptions.create!(subscriber: person, excluded: true)
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
      list.subscriptions.create(subscriber: event)
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
      list.subscriptions.create!(subscriber: bottom_layer_one,
                                 role_types: ['Group::BottomLayer::Member'])
      expect(subject).to have(1).item
    end

    it 'is present when created for ancestor group' do
      list.subscriptions.create!(subscriber: top_layer, role_types: ['Group::BottomLayer::Member'])
      expect(subject).to have(1).item
    end

    it 'is empty when created for sibling group' do
      list.subscriptions.create!(subscriber: bottom_layer_two,
                                 role_types: ['Group::BottomLayer::Member'])
      expect(subject).to be_empty
    end

    it 'is empty when tag required' do
      subscription_tag = SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create!(name: 'foo'))
      list.subscriptions.create!(subscriber: bottom_layer_one,
                                 role_types: ['Group::BottomLayer::Member'], subscription_tags: [subscription_tag])
      expect(subject).to be_empty
    end

    it 'is present when tag is required and any person matches and tag does not exclude' do
      subscription_tag = SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create!(name: 'foo'),
                                             excluded: false)
      list.subscriptions.create!(subscriber: bottom_layer_one,
                                 role_types: ['Group::BottomLayer::Member'], subscription_tags: [subscription_tag])
      person.update!(tag_list: %w(foo buz))
      expect(subject).to have(1).item
    end

    it 'is empty when tag is required and any person matches and tag does exclude' do
      subscription_tag = SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create!(name: 'foo'),
                                             excluded: true)
      subscription_tag2 = SubscriptionTag.new(tag: ActsAsTaggableOn::Tag.create!(name: 'bar'),
                                              excluded: false)
      list.subscriptions.create!(subscriber: bottom_layer_one,
                                 role_types: ['Group::BottomLayer::Member'], subscription_tags: [subscription_tag, subscription_tag2])
      person.update!(tag_list: %w(foo bar))
      expect(subject).to be_empty
    end

    it 'is empty when the person has no roles' do
      list.subscriptions.create!(subscriber: bottom_layer_one,
                                 role_types: ['Group::BottomLayer::Member'])
      person.roles.destroy_all
      expect(subject).to be_empty
    end

  end

end
