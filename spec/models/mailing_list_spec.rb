require 'spec_helper'

describe MailingList do
  
  let(:list)   { Fabricate(:mailing_list, group: groups(:top_layer)) }
  let(:person) { Fabricate(:person) }
  let(:event)  { Fabricate(:event, groups: [list.group]) }
  
  describe 'validations' do
    # TODO
  end
  
  describe '#subscribed?' do
    context "people" do
      it "is true if included" do
        create_subscription(person)
        
        list.subscribed?(person).should be_true
        list.subscribed?(people(:top_leader)).should be_false
      end
      
      it "is false if excluded" do
        create_subscription(person)
        create_subscription(person, true)
        
        list.subscribed?(person).should be_false
      end
    end
    
    context "events" do
      it "is true if active participation" do
        create_subscription(event)
        p = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        
        list.subscribed?(p).should be_true
      end
      
      it "is false if non active participation" do
        create_subscription(event)
        p = Fabricate(:event_participation, event: event).person
        
        list.subscribed?(p).should be_false
      end 
      
      it "is false if explicitly excluded" do
        create_subscription(event)
        p = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        create_subscription(p, true)
        
        list.subscribed?(p).should be_false
      end
    end
    
    context "groups" do
      it "is true if in group" do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        
        list.subscribed?(p).should be_true
      end
      
      it "is false if different role in groupn" do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        p = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
        
        list.subscribed?(p).should be_false
      end 
      
      it "is false if explicitly excluded" do
        sub = create_subscription(groups(:bottom_layer_one), false, 
                                  Group::BottomGroup::Leader.sti_name)
        p = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        create_subscription(p, true)
        
        list.subscribed?(p).should be_false
      end
    end
  end
  
  describe '#people' do
    
    subject { list.people }
    
    
    context "only people" do
      it "includes single person" do
        create_subscription(person)
        
        should include(person)
        should have(1).item
      end
      
      it "includes various people" do
        create_subscription(person)
        create_subscription(people(:top_leader))
        
        should include(person)
        should include(people(:top_leader))
        should have(2).items
      end
    end
     
    context "only events" do
      it "includes all event participations" do
        create_subscription(event)
        leader = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation
        Fabricate(Event::Role::Treasurer.name.to_sym, participation: leader)
        p1 = leader.person
        p2 = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        
        should include(p1)
        should include(p2)
        should have(2).items
      end
      
      it "includes people from multiple events" do
        create_subscription(event)
        p1 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        p2 = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        
        e2 = Fabricate(:event, groups: [list.group])
        create_subscription(e2)
        p3 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: e2)).participation.person
        Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: e2, person: p1))
        
        # only participation without role
        Fabricate(:event_participation, event: e2)
        
        # different event in same group
        Fabricate(Event::Role::Participant.name.to_sym, 
                  participation: Fabricate(:event_participation, 
                                           event: Fabricate(:event, groups: [list.group])))
        
        should include(p1)
        should include(p2)
        should include(p3)
        should have(3).items
      end
    end
    
    context "only groups" do
      it "includes people with the given roles" do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        
        role = Group::BottomGroup::Leader.name.to_sym
        p1 = Fabricate(role, group: groups(:bottom_group_one_one)).person
        p2 = Fabricate(role, group: groups(:bottom_group_one_two)).person
        # role in a group in different hierarchy
        Fabricate(role, group: groups(:bottom_group_two_one))
        # role in a group in different hierarchy and different role in same hierarchy
        p3 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
        Fabricate(role, group: groups(:bottom_group_two_one), person: p3)
        
        should include(p1)
        should include(p2)
        should have(2).items
      end
      
      it "includes people with the given roles in multiple groups" do
        sub1 = create_subscription(groups(:bottom_layer_one), false,
                                   Group::BottomLayer::Leader.sti_name,
                                   Group::BottomGroup::Leader.sti_name)
        sub2 = create_subscription(groups(:bottom_group_one_one), false,
                                   Group::BottomGroup::Member.sti_name)
        
        p1 = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
        p2 = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        p3 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
        # role in a group in different hierarchy
        Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one))
        Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two))
        
        should include(p1)
        should include(p2)
        should include(p3)
        should have(3).items
      end
    end
    
    context "people with excluded" do
      it "excludes people" do
        create_subscription(person)
        create_subscription(people(:top_leader))
        create_subscription(person, true)
        
        should include(people(:top_leader))
        should have(1).items
      end
    end
    
    context "events with excluded" do
      it "excludes person from events" do
        create_subscription(event)
        p1 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        p2 = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        
        e2 = Fabricate(:event, groups: [list.group])
        create_subscription(e2)
        p3 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: e2)).participation.person
        Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: e2, person: p1))
        
        create_subscription(p1, true)
        
        should include(p2)
        should include(p3)
        should have(2).items
      end
    end
    
    context "groups with excluded" do
      it "excludes person from groups" do
        sub = create_subscription(groups(:bottom_layer_one), false,
                                  Group::BottomGroup::Leader.sti_name)
        
        role = Group::BottomGroup::Leader.name.to_sym
        p1 = Fabricate(role, group: groups(:bottom_group_one_one)).person
        p2 = Fabricate(role, group: groups(:bottom_group_one_two)).person

        create_subscription(p2, true)
        
        should include(p1)
        should have(1).items
      end
    end
    
    context "all" do
      it "includes different people from events and groups" do
        # people
        create_subscription(person)
        create_subscription(people(:top_leader))
        
        # events
        create_subscription(event)
        pe1 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        pe2 = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        
        e2 = Fabricate(:event, groups: [list.group])
        create_subscription(e2)
        pe3 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: e2)).participation.person
        Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: e2, person: pe1))
        
        
        # groups
        sub1 = create_subscription(groups(:bottom_layer_one), false,
                                   Group::BottomLayer::Leader.sti_name,
                                   Group::BottomGroup::Leader.sti_name)
        sub2 = create_subscription(groups(:bottom_group_one_one), false,
                                   Group::BottomGroup::Member.sti_name)
        
        pg1 = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
        pg2 = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        pg3 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
        # role in a group in different hierarchy
        Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one))
        Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_two))
        
        should include(person)
        should include(people(:top_leader))
        should include(pe1)
        should include(pe2)
        should include(pe3)
        should include(pg1)
        should include(pg2)
        should include(pg3)
        should have(8).items
      end
      
      it "includes overlapping people from events and groups" do
        # people
        create_subscription(people(:top_leader))
        
        # events
        create_subscription(event)
        pe1 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        pe2 = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        
        e2 = Fabricate(:event, groups: [list.group])
        create_subscription(e2)
        pe3 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: e2)).participation.person
        Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: e2, person: pe1))
        
        
        # groups
        sub1 = create_subscription(groups(:bottom_layer_one), false,
                                   Group::BottomLayer::Leader.sti_name,
                                   Group::BottomGroup::Leader.sti_name)
        sub2 = create_subscription(groups(:bottom_group_one_one), false,
                                   Group::BottomGroup::Member.sti_name)
        
        pg1 = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
        pg2 = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: pe3)
        
        create_subscription(pg2)
        
        should include(people(:top_leader))
        should include(pe1)
        should include(pe2)
        should include(pe3)
        should include(pg1)
        should include(pg2)
        should have(6).items
      end
    end
    
    context "all with excluded" do
      
      it "excludes overlapping people from events and groups" do
        # people
        create_subscription(people(:top_leader))
        
        # events
        create_subscription(event)
        pe1 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        pe2 = Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event)).participation.person
        
        e2 = Fabricate(:event, groups: [list.group])
        create_subscription(e2)
        pe3 = Fabricate(Event::Role::Leader.name.to_sym, participation: Fabricate(:event_participation, event: e2)).participation.person
        Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: e2, person: pe1))
        
        
        # groups
        sub1 = create_subscription(groups(:bottom_layer_one), false,
                                   Group::BottomLayer::Leader.sti_name,
                                   Group::BottomGroup::Leader.sti_name)
        sub2 = create_subscription(groups(:bottom_group_one_one), false, 
                                   Group::BottomGroup::Member.sti_name)
        
        pg1 = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
        pg2 = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: pe3)
        
        create_subscription(pg2, true)
        create_subscription(pe1, true)
        
        should include(people(:top_leader))
        should include(pe2)
        should include(pe3)
        should include(pg1)
        should have(4).items
        
        list.subscribed?(people(:top_leader)).should be_true
        list.subscribed?(pe2).should be_true
        list.subscribed?(pe3).should be_true
        list.subscribed?(pg1).should be_true
        list.subscribed?(pg2).should be_false
        list.subscribed?(pe1).should be_false
      end
    end
  end
  
  def create_subscription(subscriber, excluded = false, *role_types)
    sub = list.subscriptions.new
    sub.subscriber = subscriber
    sub.excluded = excluded
    sub.related_role_types = role_types.collect {|t| RelatedRoleType.new(role_type: t) }
    sub.save!
    sub
  end
  
end
