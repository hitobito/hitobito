# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::QualificationFilter do

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:kind) { nil }
  let(:validity) { 'all' }
  let(:qualification_kind_ids) { [] }

  let(:list_filter) do
    Person::QualificationFilter.new(group,
                                    user,
                                    kind: kind,
                                    qualification_kind_id: qualification_kind_ids,
                                    validity: validity)
  end

  let(:entries) { list_filter.filter_entries }

  let(:bl_leader) { create_person(Group::BottomLayer::Leader, :bottom_layer_one, 'reactivateable', :sl, :gl_leader) }

  before do
    @tg_member = create_person(Group::TopGroup::Member, :top_group, 'active', :sl)
    # duplicate qualification
    Fabricate(:qualification, person: @tg_member, qualification_kind: qualification_kinds(:sl), start_at: Date.today - 2.weeks)

    @tg_extern = create_person(Role::External, :top_group, 'active', :sl)

    @bl_leader = bl_leader
    @bl_extern = create_person(Role::External, :bottom_layer_one, 'reactivateable', :gl_leader)

    @bg_leader = create_person(Group::BottomGroup::Leader, :bottom_group_one_one, 'all', :sl, :ql)
    @bg_member = create_person(Group::BottomGroup::Member, :bottom_group_one_one, 'active', :sl)
  end

  def create_person(role, group, validity, *qualification_kinds)
    person = Fabricate(role.name.to_sym, group: groups(group)).person
    qualification_kinds.each do |key|
      kind = qualification_kinds(key)
      start = case validity
      when 'active' then Date.today
      when 'reactivateable' then Date.today - kind.validity.years - 1.year
      else Date.today - 20.years
      end
      Fabricate(:qualification, person: person, qualification_kind: kind, start_at: start)
    end
    person
  end

  context 'no filter' do
    it 'loads only entries on group' do
      expect(entries).to be_empty
    end

    it 'count is 0' do
      expect(list_filter.all_count).to eq(0)
    end
  end

  context 'kind deep' do
    let(:kind) { 'deep' }

    context 'no qualification kinds' do
      it 'loads only entries on group' do
        expect(entries).to be_empty
      end

    end

    context 'with qualification kinds' do
      let(:qualification_kind_ids) { qualification_kinds(:sl, :gl_leader).collect(&:id) }

      it 'loads all entries in layer and below' do
        expect(entries).to match_array([@tg_member, @tg_extern, @bl_leader, @bg_leader])
      end

      it 'contains only visible people' do
        expect(entries.size).to eq(list_filter.all_count - 2)
      end
    end
  end

  context 'kind layer' do
    let(:kind) { 'layer' }

    context 'with qualification kinds' do
      let(:qualification_kind_ids) { qualification_kinds(:sl, :gl_leader).collect(&:id) }

      it 'loads all entries in layer' do
        expect(entries).to match_array([@tg_member, @tg_extern])
      end

      it 'contains all people' do
        expect(entries.size).to eq(list_filter.all_count)
      end
    end
  end

  context 'in bottom layer' do
    let(:user) { bl_leader }
    let(:kind) { 'layer' }
    let(:group) { groups(:bottom_layer_one) }
    let(:qualification_kind_ids) { qualification_kinds(:sl, :gl_leader).collect(&:id) }

    context 'active validities' do

      let(:validity) { 'active' }

      it 'loads matched entries' do
        expect(entries).to match_array([@bg_member])
      end

      it 'contains all people' do
        expect(entries.size).to eq(list_filter.all_count)
      end

      context 'with infinite qualifications' do
        let(:qualification_kind_ids) { qualification_kinds(:sl, :ql).collect(&:id) }
        it 'contains them' do
          expect(entries).to match_array([@bg_member, @bg_leader])
        end
      end

      context 'as top leader' do
        let(:user) { people(:top_leader) }

        it 'does not load non-visible entries' do
          expect(entries).to match_array([])
        end

        it 'contains only visible people' do
          expect(entries.size).to eq(list_filter.all_count - 1)
        end
      end
    end

    context 'reactivateable validities' do
      let(:validity) { 'reactivateable' }

      it 'loads matched entries' do
        expect(entries).to match_array([@bg_member, @bl_extern, @bl_leader])
      end

      it 'contains all people' do
        expect(entries.size).to eq(list_filter.all_count)
      end

      context 'with infinite qualifications' do
        let(:qualification_kind_ids) { qualification_kinds(:sl, :ql).collect(&:id) }
        it 'contains them' do
          expect(entries).to match_array([@bg_member, @bg_leader])
        end
      end
    end

    context 'all validities' do
      let(:validity) { 'alll' }

      it 'loads matched entries' do
        expect(entries).to match_array([@bg_member, @bl_extern, @bg_leader, @bl_leader])
      end

      it 'contains all people' do
        expect(entries.size).to eq(list_filter.all_count)
      end
    end
  end

end