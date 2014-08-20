# encoding: utf-8

#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleRelation do

  before do
    PeopleRelation.kind_opposites['parent'] = 'child'
    PeopleRelation.kind_opposites['child'] = 'parent'
  end

  after do
    PeopleRelation.kind_opposites.clear
  end

  let(:person) { people(:top_leader) }
  let(:other) { people(:bottom_member) }

  include_examples 'people relation kinds'

  context 'always come together' do
    it 'on creation' do
      r = nil
      expect do
        r = PeopleRelation.create!(head_id: person.id, tail_id: other.id, kind: 'parent')
      end.to change { PeopleRelation.count }.by(2)
      o = r.opposite
      o.head_id.should eq(r.tail_id)
      o.tail_id.should eq(r.head_id)
      o.kind.should eq('child')
    end

    it 'on delete' do
      r = PeopleRelation.create!(head_id: person.id, tail_id: other.id, kind: 'parent')
      expect do
        r.destroy
      end.to change { PeopleRelation.count }.by(-2)
    end

    it 'on delete with changed attrs' do
      r = PeopleRelation.create!(head_id: person.id, tail_id: other.id, kind: 'parent')
      r.tail_id = Fabricate(:person).id
      expect do
        r.destroy
      end.to change { PeopleRelation.count }.by(-2)
    end

    it 'on update of tail' do
      r = PeopleRelation.create!(head_id: person.id, tail_id: other.id, kind: 'parent')
      p = Fabricate(:person)
      expect do
        r.update(tail_id: p.id)
      end.not_to change { PeopleRelation.count }
      o = r.opposite
      o.head_id.should eq(r.tail_id)
      o.tail_id.should eq(r.head_id)
      o.kind.should eq('child')
    end

    it 'on update of kind' do
      r = PeopleRelation.create!(head_id: person.id, tail_id: other.id, kind: 'parent')
      expect do
        r.update(kind: 'child')
      end.not_to change { PeopleRelation.count }
      o = r.opposite
      o.head_id.should eq(r.tail_id)
      o.tail_id.should eq(r.head_id)
      o.kind.should eq('parent')
    end
  end

  context 'validations' do
    it 'succeeds' do
      r = PeopleRelation.new(head_id: person.id, tail_id: other.id, kind: 'parent')
      r.should be_valid
    end

    it 'fail with same head and tail' do
      r = PeopleRelation.new(head_id: person.id, tail_id: person.id, kind: 'parent')
      r.should_not be_valid
    end

    it 'fails with illegal kind' do
      r = PeopleRelation.new(head_id: person.id, tail_id: other.id, kind: 'mother')
      r.should_not be_valid
    end

    it 'fails without kind' do
      r = PeopleRelation.new(head_id: person.id, tail_id: other.id)
      r.should_not be_valid
    end

    it 'fails without tail' do
      r = PeopleRelation.new(head_id: person.id, kind: 'parent')
      r.should_not be_valid
    end
  end
end
