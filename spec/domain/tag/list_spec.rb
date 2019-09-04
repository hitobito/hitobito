#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Tag::List do

  let(:person1) { people(:top_leader) }
  let(:person2) { people(:bottom_member) }
  let(:tag1) { ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('No mail') }
  let(:tag2) { ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('Category: Value') }

  context 'add tags' do
    it 'creates only one tag for one person' do
      tag_list = Tag::List.new([person1], [tag1])
      expect do
        expect(tag_list.add).to be 1
      end.to change { person1.tags.count }.by(1)
    end

    it 'does nothing if the tag already exists' do
      person = people(:top_leader)
      person.tag_list.add(tag1)
      person.save!
      tag_list = Tag::List.new([person], [tag1])
      expect do
        expect(tag_list.add).to be 0
      end.not_to(change { person1.reload.tags })
    end

    it 'may create the same tag on multiple people' do
      tag_list = Tag::List.new([person1, person2], [tag1])
      expect do
        expect(tag_list.add).to be 2
      end.to change { person1.tags.count }.by(1).and change { person2.tags.count }.by(1)

      expect(person1.reload.tags.collect(&:name)).to include tag1.name
      expect(person2.reload.tags.collect(&:name)).to include tag1.name
    end

    it 'may create multiple tags for one person' do
      tag_list = Tag::List.new([person1], [tag1, tag2])
      expect do
        expect(tag_list.add).to be 2
      end.to change { person1.tags.count }.by(2)

      expect(person1.reload.tags.collect(&:name)).to include tag1.name, tag2.name
    end

    it 'may create multiple tags on multiple people' do
      person2.tag_list.add(tag2)
      person2.save!
      tag_list = Tag::List.new([person1, person2], [tag1, tag2])
      expect do
        expect(tag_list.add).to be 3
      end.to change { person1.tags.count }.by(2).and change { person2.tags.count }.by(1)

      expect(person1.reload.tags.collect(&:name)).to include tag1.name, tag2.name
      expect(person2.reload.tags.collect(&:name)).to include tag1.name, tag2.name
    end
  end

  context 'remove tags' do
    it 'deletes only one tag from one person' do
      person1.tag_list.add(tag1)
      person1.save!
      tag_list = Tag::List.new([person1], [tag1])
      expect do
        expect(tag_list.remove).to be 1
      end.to change { person1.tags.count }.by(-1)
    end

    it 'does nothing if the tag does not exist on the person' do
      tag_list = Tag::List.new([person1], [tag1])
      expect do
        expect(tag_list.remove).to be 0
      end.not_to(change { person1.reload.tags })
    end

    it 'may delete the same tag from multiple people' do
      person1.tag_list.add(tag1)
      person1.save!
      person2.tag_list.add(tag1)
      person2.save!
      tag_list = Tag::List.new([person1, person2], [tag1])
      expect do
        expect(tag_list.remove).to be 2
      end.to change { person1.tags.count }.by(-1).and change { person2.tags.count }.by(-1)

      expect(person1.reload.tags.collect(&:name)).not_to include tag1.name
      expect(person2.reload.tags.collect(&:name)).not_to include tag1.name
    end

    it 'may delete multiple tags from one person' do
      person1.tag_list.add(tag1, tag2)
      person1.save!
      tag_list = Tag::List.new([person1], [tag1, tag2])
      expect do
        expect(tag_list.remove).to be 2
      end.to change { person1.tags.count }.by(-2)

      expect(person1.reload.tags.collect(&:name)).not_to include tag1.name, tag2.name
    end

    it 'may delete multiple tags from multiple people' do
      person1.tag_list.add(tag1, tag2)
      person1.save!
      person2.tag_list.add(tag1)
      person2.save!
      tag_list = Tag::List.new([person1, person2], [tag1, tag2])
      expect do
        expect(tag_list.remove).to be 3
      end.to change { person1.tags.count }.by(-2).and change { person2.tags.count }.by(-1)

      expect(person1.reload.tags.collect(&:name)).not_to include tag1.name, tag2.name
      expect(person2.reload.tags.collect(&:name)).not_to include tag1.name, tag2.name
    end
  end

end
