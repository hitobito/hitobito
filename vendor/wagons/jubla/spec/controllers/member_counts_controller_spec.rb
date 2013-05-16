require 'spec_helper'

describe MemberCountsController do

  let(:flock) { groups(:bern) }

  before { sign_in(people(:top_leader)) }

  describe "GET edit" do
    context "in 2012" do
      before { get :edit, group_id: flock.id, year: 2012 }

      it "assigns counts" do
        assigns(:member_counts).should have(3).items
        assigns(:group).should == flock
      end
    end

    it "without year raises exception" do
      expect { get :edit, group_id: flock.id }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PUT update" do
    context "as federal leader" do
      before do
        put :update, group_id: flock.id, year: 2012, member_count:
                      { member_counts(:bern_1985).id => {leader_f: 3, leader_m: 1, child_f: '', child_m: '0'},
                        member_counts(:bern_1988).id => {leader_f: 2, leader_m: 0, child_f: nil, child_m: 1},
                        member_counts(:bern_1997).id => {leader_f: 0, leader_m: 0, child_f: 5, child_m: 2},
                      }

      end

      it { should redirect_to(census_flock_group_path(flock, year: 2012)) }

      it "should save counts" do
        assert_member_counts(member_counts(:bern_1985).reload, 3, 1, nil, 0)
        assert_member_counts(member_counts(:bern_1988).reload, 2, 0, nil, 1)
        assert_member_counts(member_counts(:bern_1997).reload, 0, 0, 5, 2)
      end
    end

    context "as flock leader" do
      it "restricts access" do
        leader = Fabricate(Group::Flock::Leader.name.to_sym, group: flock).person
        sign_in(leader)
        expect { put :update, group_id: flock.id, year: 2012, member_count: {} }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "POST create" do
    it "handles request with redirect" do
      censuses(:two_o_12).destroy
      post :create, group_id: flock.id

      should redirect_to(census_flock_group_path(flock, year: 2011))
      flash[:notice].should be_present
    end

    it "should not change anything if counts exist" do
      expect { post :create, group_id: flock.id }.not_to change{ MemberCount.count }
    end

    it "should create counts" do
      Fabricate(Group::Flock::Leader.name.to_sym, group: flock,
                person: Fabricate(:person, gender: 'm', birthday: Date.new(1980, 1, 1)))
      Fabricate(Group::Flock::Guide.name.to_sym, group: flock,
                person: Fabricate(:person, gender: 'w', birthday: Date.new(1982, 1, 1)))
      Fabricate(Group::ChildGroup::Child.name.to_sym, group: groups(:asterix),
                person: Fabricate(:person, gender: 'm', birthday: Date.new(2000, 12, 31)))
      censuses(:two_o_12).destroy
      expect { post :create, group_id: flock.id }.to change{ MemberCount.count }.by(4)

      counts = MemberCount.where(flock_id: flock.id, year: 2011).order(:born_in).to_a
      counts.should have(4).items

      assert_member_counts(counts[0], 1, nil, 1, nil)
      assert_member_counts(counts[1], nil, 1, nil, nil)
      assert_member_counts(counts[2], 1, nil, nil, nil)
      assert_member_counts(counts[3], nil, nil, nil, 1)
    end

    context "as flock leader" do
      it "creates counts" do
        censuses(:two_o_12).destroy
        leader = Fabricate(Group::Flock::Leader.name.to_sym, group: flock).person
        sign_in(leader)
        post :create, group_id: flock.id

        should redirect_to(census_flock_group_path(flock, year: 2011))
        flash[:notice].should be_present
      end
    end

    context "as guide" do
      it "restricts access" do
        guide = Fabricate(Group::Flock::Guide.name.to_sym, group: flock).person
        sign_in(guide)
        expect { post :create, group_id: flock.id }.to raise_error(CanCan::AccessDenied)
      end
    end
  end


  def assert_member_counts(count, leader_f, leader_m, child_f, child_m)
    count.leader_f.should == leader_f
    count.leader_m.should == leader_m
    count.child_f.should == child_f
    count.child_m.should == child_m
  end

end
