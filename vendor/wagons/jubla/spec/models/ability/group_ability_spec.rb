require 'spec_helper'


describe GroupAbility do


  subject { ability }
  let(:ability) { Ability.new(role.person.reload) }


  context "layer full" do
    let(:role) { Fabricate(Group::FederalBoard::Member.name.to_sym, group: groups(:federal_board)) }

    context "without specific group" do
      it "may not create subgroup" do
        should_not be_able_to(:create, Group.new)
      end
    end

    context "in own group" do
      let(:group) { role.group }
      it "may create subgroup" do
        should be_able_to(:create, group.children.new)
      end

      it "may edit group" do
        should be_able_to(:update, group)
      end

      it "may not modify superior" do
        should_not be_able_to(:modify_superior, group)
      end
    end

    context "in group from lower layer" do
      let(:group) { groups(:bern) }
      it "may create subgroup" do
        should be_able_to(:create, group.children.new)
      end

      it "may edit group" do
        should be_able_to(:update, group)
      end

      it "may modify superior" do
        should be_able_to(:modify_superior, group)
      end

      it "may modify superior in new group" do
        should be_able_to(:modify_superior, group.parent.children.new)
      end
    end
  end

  context "layer full in flock" do
    let(:role) { Fabricate(Group::Flock::Leader.name.to_sym, group: groups(:bern)) }

    context "in own group" do
      let(:group) { role.group }

      it "may edit group" do
        should be_able_to(:update, group)
      end

      it "may not modify superior" do
        should_not be_able_to(:modify_superior, group)
      end
    end
  end

  context "group full" do
    let(:role) { Fabricate(Group::StateProfessionalGroup::GroupAdmin.name.to_sym, group: groups(:be_security)) }

    context "in own group" do
      let(:group) { role.group }
      it "may not create subgroup" do
        should_not be_able_to(:create, group.children.new)
      end

      it "may edit group" do
        should be_able_to(:update, group)
      end

      it "may not modify superior" do
        should_not be_able_to(:modify_superior, group)
      end
    end

    context "without specific group" do
      it "may not create subgroup" do
        should_not be_able_to(:create, Group.new)
      end
    end

    context "in other group from same layer" do
      let(:group) { groups(:be_board) }
      it "may not create subgroup" do
        should_not be_able_to(:create, group.children.new)
      end
    end

    context "in group from lower layer" do
      let(:group) { groups(:bern) }
      it "may not create subgroup" do
        should_not be_able_to(:create, group.children.new)
      end
    end

    context "in group from other layer" do
      let(:group) { groups(:no_board) }
      it "may not create subgroup" do
        should_not be_able_to(:create, group.children.new)
      end
    end
  end

  context "deleted group" do
    let(:role) { Fabricate(Group::Flock::Leader.name.to_sym, group: group) }
    let(:group) { groups(:ausserroden) }
    before { group.destroy }

    it "may not create subgroup" do
      should_not be_able_to(:create, group.children.new)
    end

    it "may not update group" do
      should_not be_able_to(:update, group)
    end

    it "may reactivate group" do
      should be_able_to(:reactivate, group)
    end
  end

end
