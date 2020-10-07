# frozen_string_literal: true

require 'spec_helper'

describe Tags::Merger do

  let(:tag1) { Fabricate(:tag) }
  let(:tag2) { Fabricate(:tag) }
  let!(:tag3) { Fabricate(:tag) }

  let!(:tag1_owner) { fabricate_tagged_person([tag1]) }
  let!(:tag2_owner) { fabricate_tagged_person([tag2]) }
  let!(:all_tag_owner) { fabricate_tagged_person([tag1, tag2]) }
  let!(:validation_tags) do
    PersonTags::Validation.tag_names.collect do |t|
      ActsAsTaggableOn::Tag.create!(name: t)
    end
  end

  let(:merger) { described_class.new(@src_tag_ids, tag1.id, @new_name) }

  context 'merge tags' do

    it 'merges tag2 into tag1' do
      @src_tag_ids = [tag2.id]

      merger.merge!

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag1])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1])
      
      expect(tag2_owner.taggings.count).to eq(1)
      expect(tag1_owner.taggings.count).to eq(1)
      expect(all_tag_owner.taggings.count).to eq(1)

      expect(tag1.reload.taggings_count).to eq(3)

      expect(ActsAsTaggableOn::Tag.where(id: tag2.id)).not_to exist
    end

    it 'merges tag2 into tag1 which are both assigned to all people' do
      @src_tag_ids = [tag2.id]
      tag1_owner.update!(tags: [tag1, tag2])
      tag2_owner.update!(tags: [tag1, tag2])

      merger.merge!

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag1])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1])
      
      expect(tag2_owner.taggings.count).to eq(1)
      expect(tag1_owner.taggings.count).to eq(1)
      expect(all_tag_owner.taggings.count).to eq(1)

      expect(tag1.reload.taggings_count).to eq(3)

      expect(ActsAsTaggableOn::Tag.where(id: tag2.id)).not_to exist
    end

    it 'merges tag2 into tag1 and updates name' do
      @src_tag_ids = [tag2.id]
      @new_name = 'Super Dry'

      merger.merge!

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag1])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1])

      expect(tag1.reload.taggings_count).to eq(3)
      expect(tag1.name).to eq('Super Dry')

      expect(ActsAsTaggableOn::Tag.where(id: tag2.id)).not_to exist
    end

    it 'does not merge tag1 into tag1' do
      @src_tag_ids = [tag1.id]

      merger.merge!

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag2])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1, tag2])

      expect(tag1.reload.taggings_count).to eq(2)
    end

    it 'does not merge validation tags' do
      @src_tag_ids = validation_tags.collect(&:id)

      merger.merge!

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag2])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1, tag2])

      expect(tag1.reload.taggings_count).to eq(2)

      validation_tags.each do |v|
        expect(ActsAsTaggableOn::Tag.where(id: v.id)).to exist
      end
    end

    it 'merges unassigned tag3' do
      @src_tag_ids = [tag3.id]

      merger.merge!

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag2])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1, tag2])

      expect(tag1.reload.taggings_count).to eq(2)

      expect(ActsAsTaggableOn::Tag.where(id: tag3.id)).not_to exist
    end

    it 'ignores non existent tag ids' do
      @src_tag_ids = [tag2.id, 42]

      merger.merge!

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag1])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1])

      expect(tag1.reload.taggings_count).to eq(3)
    end

    it 'ignores non number ids' do
      @src_tag_ids = [tag2.id, 'super-dry']

      merger.merge!

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag1])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1])

      expect(tag1.reload.taggings_count).to eq(3)
    end
  end

  private

  def fabricate_tagged_person(tags)
    person = Fabricate(:person)
    person.update!(tags: tags)
    person
  end
end
