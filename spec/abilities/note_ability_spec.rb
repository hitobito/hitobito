#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe NoteAbility do
  subject { ability }

  let(:ability) { Ability.new(role.person.reload) }

  context :layer_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it "may create and destroy note in his layer" do
      other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
      note = create_note(role.person, other)
      is_expected.to be_able_to(:create, note)
      is_expected.to be_able_to(:destroy, note)
    end

    it "may create and destroy note in bottom layer" do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
      note = create_note(role.person, other)
      is_expected.to be_able_to(:create, note)
      is_expected.to be_able_to(:destroy, note)
    end
  end

  context "layer_and_below_full in bottom layer" do
    let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

    it "may create and destroy note in his layer" do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
      note = create_note(role.person, other)
      is_expected.to be_able_to(:create, note)
      is_expected.to be_able_to(:destroy, note)
    end

    it "may not create and destroy note in top layer" do
      other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
      note = create_note(role.person, other)
      is_expected.not_to be_able_to(:create, note)
      is_expected.not_to be_able_to(:destroy, note)
    end
  end

  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

    it "may create and destroy note in his layer" do
      other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
      note = create_note(role.person, other)
      is_expected.to be_able_to(:create, note)
      is_expected.to be_able_to(:destroy, note)
    end

    it "may not create or delete note in bottom layer" do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
      note = create_note(role.person, other)
      is_expected.not_to be_able_to(:create, note)
      is_expected.not_to be_able_to(:destroy, note)
    end
  end

  context "layer_full in bottom layer" do
    let(:role) { Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one)) }

    it "may create or delete note in his layer" do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
      note = create_note(role.person, other)
      is_expected.to be_able_to(:create, note)
      is_expected.to be_able_to(:destroy, note)
    end

    it "may not create or delete note in upper layer" do
      other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
      note = create_note(role.person, other)
      is_expected.not_to be_able_to(:create, note)
      is_expected.not_to be_able_to(:destroy, note)
    end
  end

  context :group_and_below_read do
    let(:role) { Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)) }

    it "may not create or delete note in his layer" do
      other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
      note = create_note(role.person, other)
      is_expected.not_to be_able_to(:create, note)
      is_expected.not_to be_able_to(:destroy, note)
    end

    it "may not create or delete note in bottom layer" do
      other = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
      note = create_note(role.person, other)
      is_expected.not_to be_able_to(:create, note)
      is_expected.not_to be_able_to(:destroy, note)
    end
  end

  def create_note(author, person)
    Note.create!(
      author: author,
      subject: person,
      text: "Lorem ipsum"
    )
  end
end
