require 'spec_helper'

describe MemberCounter do

  let(:flock) { groups(:bern) }

  before do
    asterix = groups(:asterix)
    obelix = groups(:obelix)
    leader = Fabricate(Group::Flock::Leader.name, group: flock, person: Fabricate(:person, gender: 'w', birthday: '1985-01-01'))
    guide = Fabricate(Group::Flock::Guide.name, group: flock, person: Fabricate(:person, gender: 'm', birthday: '1989-01-01'))
    Fabricate(Group::ChildGroup::Leader.name, group: asterix, person: Fabricate(:person, gender: 'w', birthday: '1988-01-01'))
    Fabricate(Group::ChildGroup::Leader.name, group: obelix, person: guide.person)
    Fabricate(Group::ChildGroup::Child.name, group: asterix, person: Fabricate(:person, gender: 'w', birthday: '1999-01-01'))
    Fabricate(Group::ChildGroup::Child.name, group: asterix, person: Fabricate(:person, gender: 'm', birthday: '1999-01-01'))
    Fabricate(Group::ChildGroup::Child.name, group: obelix, person: Fabricate(:person, gender: 'w', birthday: '1999-02-02'))
    # external roles, not counted
    Fabricate(Jubla::Role::External.name, group: obelix, person: Fabricate(:person, gender: 'm', birthday: '1971-01-01'))
    Fabricate(Group::Flock::Coach.name, group: flock, person: Fabricate(:person, gender: 'w', birthday: '1972-01-01'))
    old = Fabricate(Group::Flock::Guide.name, group: flock, person: Fabricate(:person, gender: 'w', birthday: '1977-03-01'), created_at: 2.years.ago)
    old.destroy # soft delete role, create alumnus
  end

  it "flock has affiliate and deleted people as well" do
    flock.people.count.should == 4
    Person.joins(:roles).where(roles: {group_id: flock.id}).count.should == 5
  end

  context "instance" do

    subject { MemberCounter.new(2011, flock) }

    it { should_not be_exists }

    its(:state) { should == groups(:be) }

    its(:members) { should have(6).items }

    it "creates member counts" do
      expect { subject.count! }.to change { MemberCount.count }.by(4)

      should be_exists

      assert_member_counts(1985, 1, nil, nil, nil)
      assert_member_counts(1988, 1, nil, nil, nil)
      assert_member_counts(1989, nil, 1, nil, nil)
      assert_member_counts(1999, nil, nil, 2, 1)
    end

  end

  context ".create_count_for" do
    it "creates count with current census" do
      censuses(:two_o_12).destroy
      expect { MemberCounter.create_counts_for(flock) }.to change { MemberCount.where(year: 2011).count }.by(4)
    end

    it "does not create counts with existing ones" do
      expect { MemberCounter.create_counts_for(flock) }.not_to change { MemberCount.count }
    end

    it "does not create counts without census" do
      Census.destroy_all
      expect { MemberCounter.create_counts_for(flock) }.not_to change { MemberCount.count }
    end
  end

  context ".current_counts?" do
    subject { MemberCounter.current_counts?(flock) }

    context "with counts" do
      it { should be_true }
    end

    context "without counts" do
      before { MemberCount.update_all(year: 2011) }
      it { should be_false }
    end

    context "with census" do
      before { Census.destroy_all }
      it { should be_false }
    end
  end

  def assert_member_counts(born_in, leader_f, leader_m, child_f, child_m)
    count = MemberCount.where(state_id: groups(:be).id, flock_id: flock.id, year: 2011, born_in: born_in).first
    count.leader_f.should == leader_f
    count.leader_m.should == leader_m
    count.child_f.should == child_f
    count.child_m.should == child_m
  end

end
