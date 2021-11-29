# frozen_string_literal: true

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
      expect(o.head_id).to eq(r.tail_id)
      expect(o.tail_id).to eq(r.head_id)
      expect(o.kind).to eq('child')
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
      end.not_to change(PeopleRelation, :count)

      o = r.opposite
      expect(o.head_id).to eq(r.tail_id)
      expect(o.tail_id).to eq(r.head_id)
      expect(o.kind).to eq('child')
    end

    it 'on update of kind' do
      r = PeopleRelation.create!(head_id: person.id, tail_id: other.id, kind: 'parent')
      expect do
        r.update(kind: 'child')
      end.not_to change(PeopleRelation, :count)
      o = r.opposite
      expect(o.head_id).to eq(r.tail_id)
      expect(o.tail_id).to eq(r.head_id)
      expect(o.kind).to eq('parent')
    end
  end

  context 'validations' do
    it 'succeeds' do
      r = PeopleRelation.new(head_id: person.id, tail_id: other.id, kind: 'parent')
      expect(r).to be_valid
    end

    it 'fail with same head and tail' do
      r = PeopleRelation.new(head_id: person.id, tail_id: person.id, kind: 'parent')
      expect(r).not_to be_valid
    end

    it 'fails with illegal kind' do
      r = PeopleRelation.new(head_id: person.id, tail_id: other.id, kind: 'mother')
      expect(r).not_to be_valid
    end

    it 'fails without kind' do
      r = PeopleRelation.new(head_id: person.id, tail_id: other.id)
      expect(r).not_to be_valid
    end

    it 'fails without tail' do
      r = PeopleRelation.new(head_id: person.id, kind: 'parent')
      expect(r).not_to be_valid
    end
  end
end
