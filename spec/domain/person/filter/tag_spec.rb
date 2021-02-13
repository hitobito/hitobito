# encoding: utf-8

#  Copyright (c) 2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::Filter::Tag do
  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }

  context :blank do
    subject { Person::Filter::Tag.new(:tag, names: ["", nil]) }

    it "is blank" do
      expect(subject).to be_blank
    end

    it "#to_params is blank" do
      expect(subject.to_params[:names]).to be_blank
    end

    it "#to_hash is blank" do
      expect(subject.to_params[:names]).to be_blank
    end
  end

  context :with_params do
    subject { Person::Filter::Tag.new(:tag, names: ["", nil, "foo"]) }

    it "is not blank" do
      expect(subject).not_to be_blank
    end

    it "#to_params inludes names" do
      expect(subject.to_params[:names]).to eq %w(foo)
    end

    it "#to_hash includes names" do
      expect(subject.to_params[:names]).to eq %w(foo)
    end
  end

  context :apply do
    let(:other) { people(:bottom_member) }

    subject { Person::Filter::Tag.new(:tag, names: %w(test1 test2)).apply(Person.all) }

    it "does not return any person if not tagged" do
      expect(subject).to be_empty
    end

    it "finds user based on single tag" do
      user.tags.create!(name: "test1")
      expect(subject).to eq [user]
    end

    it "finds user only once even though tagged twice" do
      user.tags.create!(name: "test1")
      user.tags.create!(name: "test2")
      expect(subject).to eq [user]
    end

    it "finds two matching users" do
      user.tags.create!(name: "test1")
      user.tags.create!(name: "test2")
      other.tags << ActsAsTaggableOn::Tag.find_by(name: "test1")

      expect(subject).to match_array([user, other])
    end
  end
end
