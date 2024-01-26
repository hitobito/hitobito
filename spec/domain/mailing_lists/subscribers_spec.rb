require 'spec_helper'

describe MailingLists::Subscribers do
  include Subscriptions::SpecHelper

  let(:list)   { Fabricate(:mailing_list, group: groups(:top_layer)) }
  let(:person) { Fabricate(:person) }
  let(:event)  do
    Fabricate(:event, groups: [list.group],
                      dates: [Fabricate(:event_date, start_at: Time.zone.today)])
  end
  subject { described_class.new(list).people }


  context 'opt_in' do
    let(:list) { mailing_lists(:leaders) }
    let(:group) { groups(:top_group) }
    let(:role) { roles(:top_leader) }
    let(:person) { role.person }

    before do
      Subscription.destroy_all
      list.update!(subscribable_for: :configured, subscribable_mode: :opt_in)
    end

    it 'excludes person if only group subscription exists' do
      create_subscription(group, false, role.type)
      expect(subject).to be_empty
    end

    it 'excludes person if only direct subscription exists' do
      create_subscription(person)
      expect(subject).to be_empty
    end

    it 'includes person if group and direct subscription exists' do
      create_subscription(group, false, role.type)
      create_subscription(person)
      expect(subject).to eq [person]
    end

    it 'includes person if event and direct subscription exists' do
      create_event_subscription
      create_subscription(person)
      expect(subject).to eq [person]
    end

    it 'excludes person via global filter' do
      create_subscription(group, false, role.type)
      create_subscription(person)
      list.update(filter_chain: { language: { allowed_values: :fr } })
      expect(subject).to be_empty
    end

    it 'includes person included in global filter' do
      create_subscription(group, false, role.type)
      create_subscription(person)
      list.update(filter_chain: { language: { allowed_values: :de } })
      expect(subject).to eq [person]
    end
  end

  context 'only people' do
    it 'includes single person' do
      create_subscription(person)

      is_expected.to include(person)
      expect(subject.size).to eq(1)
    end

    it 'includes various people' do
      create_subscription(person)
      create_subscription(people(:top_leader))

      is_expected.to include(person)
      is_expected.to include(people(:top_leader))
      expect(subject.size).to eq(2)
    end
  end

  context 'only events' do
    it 'includes all event participations' do
      create_subscription(event)
      leader = Fabricate(Event::Role::Leader.name.to_sym,
                         participation: Fabricate(:event_participation, event: event)).participation
      Fabricate(Event::Role::Treasurer.name.to_sym, participation: leader)
      p1 = leader.person
      p2 = Fabricate(Event::Role::Participant.name.to_sym,
                     participation: Fabricate(:event_participation,
                                              event: event)).participation.person

      is_expected.to include(p1)
      is_expected.to include(p2)
      expect(subject.size).to eq(2)
    end

    it 'includes people from multiple events' do
      create_subscription(event)
      p1 = Fabricate(Event::Role::Leader.name.to_sym,
                     participation: Fabricate(:event_participation,
                                              event: event)).participation.person
      p2 = Fabricate(Event::Role::Participant.name.to_sym,
                     participation: Fabricate(:event_participation,
                                              event: event)).participation.person

      e2 = Fabricate(:event, groups: [list.group],
                             dates: [Fabricate(:event_date, start_at: Time.zone.today)])
      create_subscription(e2)
      p3 = Fabricate(Event::Role::Leader.name.to_sym,
                     participation: Fabricate(:event_participation, event: e2)).participation.person
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: Fabricate(:event_participation, event: e2, person: p1))

      # only participation without role
      Fabricate(:event_participation, event: e2)

      # different event in same group
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: Fabricate(:event_participation,
                                         event: Fabricate(:event, groups: [list.group])))

      is_expected.to include(p1)
      is_expected.to include(p2)
      is_expected.to include(p3)
      expect(subject.size).to eq(3)
    end
  end

  context 'only groups' do
    it 'includes people with the given roles' do
      create_subscription(groups(:bottom_layer_one), false,
                          Group::BottomGroup::Leader.sti_name)

      role = Group::BottomGroup::Leader.name.to_sym
      p1 = Fabricate(role, group: groups(:bottom_group_one_one)).person
      p2 = Fabricate(role, group: groups(:bottom_group_one_two)).person
      # role in a group in different hierarchy
      Fabricate(role, group: groups(:bottom_group_two_one))
      # role in a group in different hierarchy and different role in same hierarchy
      p3 = Fabricate(Group::BottomGroup::Member.name.to_sym,
                     group: groups(:bottom_group_one_one)).person
      Fabricate(role, group: groups(:bottom_group_two_one), person: p3)
      # deleted role in the same hierarchy
      p4 = Fabricate(role, group: groups(:bottom_group_one_one), created_at: 2.years.ago,
                           deleted_at: 1.year.ago).person

      is_expected.to include(p1)
      is_expected.to include(p2)
      is_expected.not_to include(p4)
      expect(subject.size).to eq(2)
    end

    it 'includes people with the given roles in multiple groups' do
      create_subscription(groups(:bottom_layer_one), false,
                          Group::BottomLayer::Leader.sti_name,
                          Group::BottomGroup::Leader.sti_name)
      create_subscription(groups(:bottom_group_one_one), false,
                          Group::BottomGroup::Member.sti_name)

      p1 = Fabricate(Group::BottomLayer::Leader.name.to_sym,
                     group: groups(:bottom_layer_one)).person
      p2 = Fabricate(Group::BottomGroup::Leader.name.to_sym,
                     group: groups(:bottom_group_one_one)).person
      p3 = Fabricate(Group::BottomGroup::Member.name.to_sym,
                     group: groups(:bottom_group_one_one)).person
      # role in a group in different hierarchy
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one))
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two))

      is_expected.to include(p1)
      is_expected.to include(p2)
      is_expected.to include(p3)
      expect(subject.size).to eq(3)
    end
  end

  context 'people with excluded' do
    it 'excludes people' do
      create_subscription(person)
      create_subscription(people(:top_leader))
      create_subscription(person, true)

      is_expected.to include(people(:top_leader))
      expect(subject.size).to eq(1)
    end
  end

  context 'events with excluded' do
    it 'excludes person from events' do
      create_subscription(event)
      p1 = Fabricate(Event::Role::Leader.name.to_sym,
                     participation: Fabricate(:event_participation,
                                              event: event)).participation.person
      p2 = Fabricate(Event::Role::Participant.name.to_sym,
                     participation: Fabricate(:event_participation,
                                              event: event)).participation.person

      e2 = Fabricate(:event, groups: [list.group],
                             dates: [Fabricate(:event_date, start_at: Time.zone.today)])
      create_subscription(e2)
      p3 = Fabricate(Event::Role::Leader.name.to_sym,
                     participation: Fabricate(:event_participation, event: e2)).participation.person
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: Fabricate(:event_participation, event: e2, person: p1))

      create_subscription(p1, true)

      is_expected.to include(p2)
      is_expected.to include(p3)
      expect(subject.size).to eq(2)
    end
  end

  context 'groups with excluded' do
    it 'excludes person from groups' do
      create_subscription(groups(:bottom_layer_one), false,
                          Group::BottomGroup::Leader.sti_name)

      role = Group::BottomGroup::Leader.name.to_sym
      p1 = Fabricate(role, group: groups(:bottom_group_one_one)).person
      p2 = Fabricate(role, group: groups(:bottom_group_one_two)).person

      create_subscription(p2, true)

      is_expected.to include(p1)
      expect(subject.size).to eq(1)
    end
  end

  context 'all' do
    it 'includes different people from events and groups' do
      # people
      create_subscription(person)
      create_subscription(people(:top_leader))

      # events
      create_subscription(event)
      pe1 = Fabricate(Event::Role::Leader.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: event)).participation.person
      pe2 = Fabricate(Event::Role::Participant.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: event)).participation.person

      e2 = Fabricate(:event, groups: [list.group],
                             dates: [Fabricate(:event_date, start_at: Time.zone.today + 200)])
      create_subscription(e2)
      pe3 = Fabricate(Event::Role::Leader.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: e2)).participation.person
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: Fabricate(:event_participation, event: e2, person: pe1))


      # groups
      create_subscription(groups(:bottom_layer_one), false,
                          Group::BottomLayer::Leader.sti_name,
                          Group::BottomGroup::Leader.sti_name)
      sub2 = create_subscription(groups(:bottom_group_one_one), false,
                                 Group::BottomGroup::Member.sti_name)
      sub2.subscription_tags = subscription_tags(%w(foo, bar))
      sub2.save!

      pg1 = Fabricate(Group::BottomLayer::Leader.name.to_sym,
                      group: groups(:bottom_layer_one)).person
      pg2 = Fabricate(Group::BottomGroup::Leader.name.to_sym,
                      group: groups(:bottom_group_one_one)).person
      pg3 = Fabricate(Group::BottomGroup::Member.name.to_sym,
                      group: groups(:bottom_group_one_one)).person
      pg3.tag_list = 'foo, bar, baz'
      pg3.save!
      pg4 = Fabricate(Group::BottomGroup::Member.name.to_sym,
                      group: groups(:bottom_group_one_one)).person
      # role in a group in different hierarchy
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one))
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two))

      is_expected.to include(person)
      is_expected.to include(people(:top_leader))
      is_expected.to include(pe1)
      is_expected.to include(pe2)
      is_expected.to include(pe3)
      is_expected.to include(pg1)
      is_expected.to include(pg2)
      is_expected.to include(pg3)
      is_expected.not_to include(pg4)
      expect(subject.size).to eq(8)
    end

    it 'includes overlapping people from events and groups' do
      # people
      create_subscription(people(:top_leader))

      # events
      create_subscription(event)
      pe1 = Fabricate(Event::Role::Leader.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: event)).participation.person
      pe2 = Fabricate(Event::Role::Participant.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: event)).participation.person

      e2 = Fabricate(:event, groups: [list.group],
                             dates: [Fabricate(:event_date, start_at: Time.zone.today - 100)])
      create_subscription(e2)
      pe3 = Fabricate(Event::Role::Leader.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: e2)).participation.person
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: Fabricate(:event_participation, event: e2, person: pe1))


      # groups
      create_subscription(groups(:bottom_layer_one), false,
                          Group::BottomLayer::Leader.sti_name,
                          Group::BottomGroup::Leader.sti_name)
      create_subscription(groups(:bottom_group_one_one), false,
                          Group::BottomGroup::Member.sti_name)

      pg1 = Fabricate(Group::BottomLayer::Leader.name.to_sym,
                      group: groups(:bottom_layer_one)).person
      pg2 = Fabricate(Group::BottomGroup::Leader.name.to_sym,
                      group: groups(:bottom_group_one_one)).person
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one),
                                                        person: pe3)

      create_subscription(pg2)

      is_expected.to include(people(:top_leader))
      is_expected.to include(pe1)
      is_expected.to include(pe2)
      is_expected.to include(pe3)
      is_expected.to include(pg1)
      is_expected.to include(pg2)
      expect(subject.size).to eq(6)
    end
  end

  context 'all with excluded' do

    it 'excludes overlapping people from events and groups' do
      # people
      create_subscription(people(:top_leader))

      # events
      create_subscription(event)
      pe1 = Fabricate(Event::Role::Leader.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: event)).participation.person
      pe2 = Fabricate(Event::Role::Participant.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: event)).participation.person

      e2 = Fabricate(:event, groups: [list.group],
                             dates: [Fabricate(:event_date, start_at: Time.zone.today)])
      create_subscription(e2)
      pe3 = Fabricate(Event::Role::Leader.name.to_sym,
                      participation: Fabricate(:event_participation,
                                               event: e2)).participation.person
      Fabricate(Event::Role::Participant.name.to_sym,
                participation: Fabricate(:event_participation, event: e2, person: pe1))


      # groups
      create_subscription(groups(:bottom_layer_one), false,
                          Group::BottomLayer::Leader.sti_name,
                          Group::BottomGroup::Leader.sti_name)
      create_subscription(groups(:bottom_group_one_one), false,
                          Group::BottomGroup::Member.sti_name)

      pg1 = Fabricate(Group::BottomLayer::Leader.name.to_sym,
                      group: groups(:bottom_layer_one)).person
      pg2 = Fabricate(Group::BottomGroup::Leader.name.to_sym,
                      group: groups(:bottom_group_one_one)).person
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one),
                                                        person: pe3)

      create_subscription(pg2, true)
      create_subscription(pe1, true)

      is_expected.to include(people(:top_leader))
      is_expected.to include(pe2)
      is_expected.to include(pe3)
      is_expected.to include(pg1)
      expect(subject.size).to eq(4)

      expect(list.subscribed?(people(:top_leader))).to be_truthy
      expect(list.subscribed?(pe2)).to be_truthy
      expect(list.subscribed?(pe3)).to be_truthy
      expect(list.subscribed?(pg1)).to be_truthy
      expect(list.subscribed?(pg2)).to be_falsey
      expect(list.subscribed?(pe1)).to be_falsey
    end
  end

  context 'tags' do
    it 'excludes people with given tag' do
      group = groups(:bottom_layer_one)
      group.roles.destroy_all
      sub = create_subscription(group, false, Group::BottomLayer::Member.sti_name)
      sub_tag = subscription_tags(%w(vegi)).first
      sub_tag.subscription = sub
      sub_tag.excluded = true
      sub_tag.save!

      100.times do
        Fabricate(Group::BottomLayer::Member.name.to_sym, group: group)
      end

      expect(group.people.count).to eq(100)

      vegi = group.people.last
      vegi.tag_list.add('vegi')
      vegi.first_name = 'Vegi'
      vegi.save!

      expect(list.subscribed?(vegi)).to eq(false)
      expect(list.people.size).to eq(99)
    end

    it 'includes people with given tag' do
      group = groups(:bottom_layer_one)
      group.roles.destroy_all
      sub = create_subscription(group, false, Group::BottomLayer::Member.sti_name)
      sub_tag = subscription_tags(%w(vegi)).first
      sub_tag.subscription = sub
      sub_tag.save!

      100.times do
        Fabricate(Group::BottomLayer::Member.name.to_sym, group: group)
      end

      expect(group.people.count).to eq(100)

      vegi = group.people.last
      vegi.tag_list.add('vegi')
      vegi.first_name = 'Vegi'
      vegi.save!

      expect(list.subscribed?(vegi)).to eq(true)
      expect(list.people.size).to eq(1)
    end
  end

  context 'filter' do
    it 'uses the filter_chain' do
      create_subscription(groups(:bottom_layer_one), false, Group::BottomGroup::Leader.sti_name)

      people = [:fr, :de, :it].to_h do |language|
        person = Fabricate(:person, language: language)
        Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one),
                                                          person: person)
        [language, person]
      end

      list.update(filter_chain: { language: { allowed_values: :fr } })
      expect(list.filter_chain).to be_a(MailingLists::Filter::Chain)
      expect(list).to receive(:filter_chain).and_call_original
      is_expected.to contain_exactly(people[:fr])
    end
  end

  describe '#subscribed?' do
    context 'people' do
      it 'is true if included' do
        create_subscription(person)

        expect(list.subscribed?(person)).to be_truthy
        expect(list.subscribed?(people(:top_leader))).to be_falsey
      end

      it 'is false if excluded' do
        create_subscription(person)
        create_subscription(person, true)

        expect(list.subscribed?(person)).to be_falsey
      end

      it 'is false if excluded via global filter' do
        create_subscription(person)
        list.update(filter_chain: { language: { allowed_values: :fr } })

        expect(list.subscribed?(person)).to be_falsey
      end

      it 'is true if not excluded via global filter' do
        create_subscription(person)
        list.update(filter_chain: { language: { allowed_values: :de } })

        expect(list.subscribed?(person)).to be_truthy
        expect(list.subscribed?(people(:top_leader))).to be_falsey
      end
    end

    context 'events' do
      it 'is true if active participation' do
        create_subscription(event)
        p = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person

        expect(list.subscribed?(p)).to be_truthy
      end

      it 'is false if non active participation' do
        create_subscription(event)
        p = Fabricate(:event_participation, event: event).person

        expect(list.subscribed?(p)).to be_falsey
      end

      it 'is false if explicitly excluded' do
        create_subscription(event)
        p = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        create_subscription(p, true)

        expect(list.subscribed?(p)).to be_falsey
      end

      it 'is false if excluded via global filter' do
        create_subscription(event)
        p = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        list.update(filter_chain: { language: { allowed_values: :fr } })

        expect(list.subscribed?(p)).to be_falsey
      end

      it 'is true if not excluded via global filter' do
        create_subscription(event)
        p = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        list.update(filter_chain: { language: { allowed_values: :de } })

        expect(list.subscribed?(p)).to be_truthy
      end
    end

    context 'groups' do
      it 'is true if in group' do
        create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person

        expect(list.subscribed?(p)).to be_truthy
      end

      it 'is true with role with future deleted_at' do
        create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one), created_at: Time.now.utc, deleted_at: Time.now.utc + 2.hours).person

        expect(list.subscribed?(p)).to be_truthy
      end

      it 'is false if different role in group' do
        create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        p = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person

        expect(list.subscribed?(p)).to be_falsey
      end

      it 'is true if in group and all tags match' do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        sub.subscription_tags = subscription_tags(%w(bar baz))
        sub.save!
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        p.tag_list = 'foo:bar, geez, baz'
        p.save!

        expect(list.subscribed?(p)).to be_truthy
      end

      it 'is true if in group and not all tags match' do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        sub.subscription_tags = subscription_tags(%w(bar foo:baz))
        sub.save!
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        p.tag_list = 'foo:baz'
        p.save!

        expect(list.subscribed?(p)).to be_truthy
      end

      it 'is false if in group and excluded tag matches' do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        sub.subscription_tags = subscription_tags(%w(bar foo:baz))
        sub.subscription_tags.second.update!(excluded: true)
        sub.save!
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        p.tag_list = 'foo:baz'
        p.save!

        expect(list.subscribed?(p)).to be_falsey
      end

      it 'is false if in group and no tags match' do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        sub.subscription_tags = subscription_tags(%w(foo:bar foo:baz))
        sub.save!
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        p.tag_list = 'baz'
        p.save!

        expect(list.subscribed?(p)).to be_falsey
      end

      it 'is false if explicitly excluded' do
        create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        create_subscription(p, true)

        expect(list.subscribed?(p)).to be_falsey
      end

      it 'is false if excluded via global filter' do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        sub.subscription_tags = subscription_tags(%w(bar foo:baz))
        sub.save!
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        p.tag_list = 'foo:baz'
        p.save!
        list.update(filter_chain: { language: { allowed_values: :fr } })

        expect(list.subscribed?(p)).to be_falsey
      end

      it 'is true if not excluded via global filter' do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        sub.subscription_tags = subscription_tags(%w(bar foo:baz))
        sub.save!
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        p.tag_list = 'foo:baz'
        p.save!
        list.update(filter_chain: { language: { allowed_values: :de } })

        expect(list.subscribed?(p)).to be_truthy
      end
    end
  end
  def create_event_subscription
    event = Fabricate(:event, groups: [group])
    event.participations.create!(person: person, active: true)
    event.reload.dates.first.update!(start_at: 10.days.ago)
    list.subscriptions.create!(subscriber: event)
  end

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
