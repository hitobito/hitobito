# encoding: utf-8

#  Copyright (c) 2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::Filter::TagAbsence do

  let(:user)  { people(:top_leader) }
  let(:group) { groups(:top_group) }

  context :blank do
    subject { Person::Filter::TagAbsence.new(:tag, names: ['', nil]) }

    it 'is blank' do
      expect(subject).to be_blank
    end

    it '#to_params is blank' do
      expect(subject.to_params[:names]).to be_blank
    end

    it '#to_hash is blank' do
      expect(subject.to_params[:names]).to be_blank
    end
  end

  context :with_params do
    subject { Person::Filter::TagAbsence.new(:tag, names: ['', nil, 'foo']) }

    it 'is not blank' do
      expect(subject).not_to be_blank
    end

    it '#to_params inludes names' do
      expect(subject.to_params[:names]).to eq %w(foo)
    end

    it '#to_hash includes names' do
      expect(subject.to_params[:names]).to eq %w(foo)
    end
  end

  context :apply do
    let(:other) { people(:bottom_member) }
    let(:root) { people(:root) }
    subject { Person::Filter::TagAbsence.new(:tag, names: %w(test1 test2)).apply(Person.all) }

    it 'does not return tagged people' do
      other.tags.create!(name: 'test1')
      user.tags << ActsAsTaggableOn::Tag.find_by(name: 'test1')

      root.tags.create!(name: 'test2')
      root.tags << ActsAsTaggableOn::Tag.find_by(name: 'test1')

      expect(subject).to be_empty
    end

    it 'does return untagged people only' do
      other.tags.create!(name: 'test1')
      root.tags.create!(name: 'test2')

      expect(subject).to eq [user]
    end
  end
end
