#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe TagList do
  let(:leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:tag1) { ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("No mail") }
  let(:tag2) { ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("Category: Value") }

  context "add tags" do
    it "creates only one tag for one person" do
      tag_list = TagList.new([leader], [tag1])
      expect {
        expect(tag_list.add).to be 1
      }.to change { leader.tags.count }.by(1)
    end

    it "does nothing if the tag already exists" do
      leader.tag_list.add(tag1)
      leader.save!
      tag_list = TagList.new([leader], [tag1])
      expect {
        expect(tag_list.add).to be 0
      }.not_to(change { leader.reload.tags.count })
    end

    it "may create the same tag on multiple people" do
      tag_list = TagList.new([leader, bottom_member], [tag1])
      expect {
        expect(tag_list.add).to be 2
      }.to change { leader.tags.count }.by(1).and change { bottom_member.tags.count }.by(1)

      expect(leader.reload.tags.collect(&:name)).to include tag1.name
      expect(bottom_member.reload.tags.collect(&:name)).to include tag1.name
    end

    it "may create multiple tags for one person" do
      tag_list = TagList.new([leader], [tag1, tag2])
      expect {
        expect(tag_list.add).to be 2
      }.to change { leader.tags.count }.by(2)

      expect(leader.reload.tags.collect(&:name)).to include tag1.name, tag2.name
    end

    it "may create multiple tags on multiple people" do
      bottom_member.tag_list.add(tag2)
      bottom_member.save!
      tag_list = TagList.new([leader, bottom_member], [tag1, tag2])
      expect {
        expect(tag_list.add).to be 3
      }.to change { leader.tags.count }.by(2).and change { bottom_member.tags.count }.by(1)

      expect(leader.reload.tags.collect(&:name)).to include tag1.name, tag2.name
      expect(bottom_member.reload.tags.collect(&:name)).to include tag1.name, tag2.name
    end
  end

  context "remove tags" do
    it "deletes only one tag from one person" do
      leader.tag_list.add(tag1)
      leader.save!
      tag_list = TagList.new([leader], [tag1])
      expect {
        expect(tag_list.remove).to be 1
      }.to change { leader.tags.count }.by(-1)
    end

    it "does nothing if the tag does not exist on the person" do
      tag_list = TagList.new([leader], [tag1])
      expect {
        expect(tag_list.remove).to be 0
      }.not_to(change { leader.reload.tags.count })
    end

    it "may delete the same tag from multiple people" do
      leader.tag_list.add(tag1)
      leader.save!
      bottom_member.tag_list.add(tag1)
      bottom_member.save!
      tag_list = TagList.new([leader, bottom_member], [tag1])
      expect {
        expect(tag_list.remove).to be 2
      }.to change { leader.tags.count }.by(-1).and change { bottom_member.tags.count }.by(-1)

      expect(leader.reload.tags.collect(&:name)).not_to include tag1.name
      expect(bottom_member.reload.tags.collect(&:name)).not_to include tag1.name
    end

    it "may delete multiple tags from one person" do
      leader.tag_list.add(tag1, tag2)
      leader.save!
      tag_list = TagList.new([leader], [tag1, tag2])
      expect {
        expect(tag_list.remove).to be 2
      }.to change { leader.tags.count }.by(-2)

      expect(leader.reload.tags.collect(&:name)).not_to include tag1.name, tag2.name
    end

    it "may delete multiple tags from multiple people" do
      leader.tag_list.add(tag1, tag2)
      leader.save!
      bottom_member.tag_list.add(tag1)
      bottom_member.save!
      tag_list = TagList.new([leader, bottom_member], [tag1, tag2])
      expect {
        expect(tag_list.remove).to be 3
      }.to change { leader.tags.count }.by(-2).and change { bottom_member.tags.count }.by(-1)

      expect(leader.reload.tags.collect(&:name)).not_to include tag1.name, tag2.name
      expect(bottom_member.reload.tags.collect(&:name)).not_to include tag1.name, tag2.name
    end
  end
end
