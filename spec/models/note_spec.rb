# frozen_string_literal: true

#  Copyright (c) 2012-2021, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Note do

  let(:author) { Fabricate(:person) }

  context '.below_in_layer' do
    it 'includes only notes from this layer for layer group' do
      n1 = create_person_note(Group::TopLayer::TopAdmin, groups(:top_layer))
      n2 = create_person_note(Group::TopGroup::LocalGuide, groups(:top_group))
      _n3 = create_person_note(Group::BottomLayer::Leader, groups(:bottom_layer_one))
      n4 = create_group_note(groups(:top_layer))
      n5 = create_group_note(groups(:top_group))
      _n6 = create_group_note(groups(:bottom_layer_one))
      expect(Note.below_in_layer(groups(:top_layer))).to match_array([n1, n2, n4, n5])
    end

    it 'includes only notes from children for non-layer group' do
      n1 = create_person_note(Group::BottomGroup::Leader, groups(:bottom_group_one_one))
      n2 = create_person_note(Group::BottomGroup::Leader, groups(:bottom_group_one_one_one))
      _n3 = create_person_note(Group::BottomGroup::Leader, groups(:bottom_group_one_two))
      n4 = create_group_note(groups(:bottom_group_one_one))
      n5 = create_group_note(groups(:bottom_group_one_one_one))
      _n6 = create_group_note(groups(:bottom_group_one_two))
      _n7 = create_group_note(groups(:bottom_layer_two))
      expect(Note.below_in_layer(groups(:bottom_group_one_one))).to match_array([n1, n2, n4, n5])
    end

    def create_person_note(role, group)
      Note.create!(subject: Fabricate(role.name.to_sym, group: group).person,
                   author_id: author.id,
                   text: 'foo')
    end

    def create_group_note(group)
      Note.create!(subject: group,
                   author_id: author.id,
                   text: 'foo')
    end
  end

  context 'dependent destroy' do
    let(:subject) { Fabricate(:person) }

    it 'gets destroyed if the person is destroyed' do
      subject.notes.create!(author_id: author.id, text: 'Lorem ipsum')
      expect(Note.count).to eq(1)
      subject.destroy!
      expect(Note.count).to eq(0)
    end

    it 'gets destroyed if the author is destroyed' do
      subject.notes.create!(author_id: author.id, text: 'Lorem ipsum')
      expect(Note.count).to eq(1)
      author.destroy!
      expect(Note.count).to eq(0)
    end
  end

  context 'validates' do
    context 'subject_type to be one of' do
      it 'Person' do
        note = Fabricate(:note, subject: Fabricate(:person))

        expect(note).to be_valid
      end

      it 'Group' do
        note = Fabricate(:note, subject: groups(:toppers))

        expect(note).to be_valid
      end
    end

    it 'subject_type to not be an Event' do
      note = Fabricate.build(:note, subject: Fabricate(:event))

      expect(note).to_not be_valid
    end
  end

end
