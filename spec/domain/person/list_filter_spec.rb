require 'spec_helper'

describe Person::ListFilter do


  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:kind) { nil }
  let(:role_types) { [] }
  let(:role_type_ids_string) { role_types.collect(&:id).join(RelatedRoleType::Assigners::ID_URL_SEPARATOR) }
  let(:list_filter) { Person::ListFilter.new(group, user, kind, role_type_ids_string) }

  let(:entries) { list_filter.filter_entries }

  before do
    @tg_member = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
    Fabricate(:phone_number, contactable: @tg_member, number: '123', label: 'Privat', public: true)
    Fabricate(:phone_number, contactable: @tg_member, number: '456', label: 'Mobile', public: false)
    Fabricate(:social_account, contactable: @tg_member, name: 'facefoo', label: 'Facebook', public: true)
    Fabricate(:social_account, contactable: @tg_member, name: 'skypefoo', label: 'Skype', public: false)
    @tg_extern = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person

    @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
    @bl_extern = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one)).person

    @bg_leader = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
    @bg_member = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
  end

  context 'group' do
    it 'loads all members of a group' do
      entries.collect(&:id).should =~ [user, @tg_member].collect(&:id)
    end

    context 'with external types' do
      let(:role_types) { [Role::External] }
      it 'loads externs of a group' do
        entries.collect(&:id).should =~ [@tg_extern].collect(&:id)
      end
    end

    context 'with specific types' do
      let(:role_types) { [Role::External, Group::TopGroup::Member] }
      it 'loads selected roles of a group' do
        entries.collect(&:id).should =~ [@tg_member, @tg_extern].collect(&:id)
      end
    end
  end

  context 'layer' do
    let(:group) { groups(:bottom_layer_one) }
    let(:kind) { 'layer' }

    context 'with layer full' do
      let(:user) { @bl_leader }

      it 'loads group members when no types given' do
        entries.collect(&:id).should =~ [people(:bottom_member), @bl_leader].collect(&:id)
      end

      context 'with specific types' do
        let(:role_types) { [Group::BottomGroup::Member, Role::External] }

        it 'loads selected roles of a group when types given' do
          entries.collect(&:id).should =~ [@bg_member, @bl_extern].collect(&:id)
        end
      end
    end

  end

  context 'deep' do
    let(:group) { groups(:top_layer) }
    let(:kind) { 'deep' }

    it 'loads group members when no types are given' do
      entries.collect(&:id).should =~ []
    end

    context 'with specific types' do
      let(:role_types) { [Group::BottomGroup::Leader, Role::External] }

      it 'loads selected roles of a group when types given' do
        entries.collect(&:id).should =~ [@bg_leader, @tg_extern].collect(&:id)
      end
    end
  end
end
