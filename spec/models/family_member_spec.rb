# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe FamilyMember do
  subject { Fabricate(:family_member) }

  context 'has basic plumbing, it' do
    it 'is an application record' do
      is_expected.to be_an ApplicationRecord
      is_expected.to be_an ActiveRecord::Base
    end

    it 'has translated kinds' do
      is_expected.to be_a I18nEnums

      expect(subject.kind).to eql 'sibling'
      expect(subject.kind_label).to eql 'Geschwister'

      expect(described_class.kind_labels).to eql(
        { sibling: 'Geschwister' }
      )
    end

    it 'is schema-validated' do
      expect(Fabricate.build(:family_member, person: nil)).to_not be_valid
      expect(Fabricate.build(:family_member, kind: nil)).to_not be_valid
      expect(Fabricate.build(:family_member, other: nil)).to_not be_valid

      expect(Fabricate.build(:family_member)).to be_valid
    end
  end

  context 'family_key' do
    let(:without_key) { Fabricate.build(:family_member, family_key: nil) }

    it 'has assumptions' do
      expect(without_key).to be_new_record
      expect(without_key.person).to_not be_nil
      expect(without_key.other).to_not be_nil
    end

    it 'is created if no family_key is known' do
      expect do
        without_key.valid? # runs before_validation hooks
      end.to change(without_key, :family_key).from(nil).to(String)
    end

    it 'is copied to both people if no family_key is known' do
      expect(without_key.person.family_key).to be_blank
      expect(without_key.other.family_key).to be_blank

      without_key.save

      family_key = without_key.family_key

      expect(without_key.person.family_key).to eql family_key
      expect(without_key.other.family_key).to eql family_key
    end

    it 'is taken from main person if other person has none' do
      family_key = SecureRandom.uuid

      without_key.person.update_attribute(:family_key, family_key)

      expect(without_key.person.family_key).to be_present
      expect(without_key.other.family_key).to be_blank
      expect(without_key.family_key).to be_blank

      without_key.save

      expect(without_key.person.family_key).to eql family_key
      expect(without_key.other.family_key).to eql family_key
      expect(without_key.family_key).to eql family_key
    end

    it 'is taken from other person if main person has none' do
      family_key = SecureRandom.uuid

      without_key.other.update_attribute(:family_key, family_key)

      expect(without_key.person.family_key).to be_blank
      expect(without_key.other.family_key).to be_present
      expect(without_key.family_key).to be_blank

      without_key.save

      expect(without_key.person.family_key).to eql family_key
      expect(without_key.other.family_key).to eql family_key
      expect(without_key.family_key).to eql family_key
    end

    it 'is taken from main person if both have the same' do
      family_key = SecureRandom.uuid

      without_key.person.update_attribute(:family_key, family_key)
      without_key.other.update_attribute(:family_key, family_key)

      expect(without_key.person.family_key).to be_present
      expect(without_key.other.family_key).to be_present
      expect(without_key.family_key).to be_blank

      without_key.save

      expect(without_key.person.family_key).to eql family_key
      expect(without_key.other.family_key).to eql family_key
      expect(without_key.family_key).to eql family_key
    end

    it 'copying fails if two different keys are present' do
      without_key.person.update_attribute(:family_key, SecureRandom.uuid)
      without_key.other.update_attribute(:family_key, SecureRandom.uuid)

      expect(without_key.person.family_key).to be_present
      expect(without_key.other.family_key).to be_present
      expect(without_key.family_key).to be_blank

      expect(without_key.person.family_key).to_not eql without_key.other.family_key

      expect do
        without_key.valid? # runs before_validation hooks
      end.to raise_error(FamilyMember::FamilyKeyMismatch)
    end

    it 'cannot be changed after creation'

    it 'does not collide with other family-keys' do
      one, two, three, other = 4.times.map { SecureRandom.uuid }

      [one, two, three].each do |key|
        fm = Fabricate(:family_member)
        expect(fm.family_key).to_not eql key

        fm.family_key = key
        fm.send(:copy_family_key, fm, fm.person, fm.other)
        fm.save!

        expect(fm.family_key).to eql key
      end

      expect(SecureRandom).to receive(:uuid).and_return(one, two, three, other)

      expect do
        without_key.valid? # runs before_validation hooks
      end.to change(without_key, :family_key).from(nil).to(other)
    end
  end

  context 'additional relations:' do
    context 'sibling is present between all siblings of a family:' do
      it 'inverse relation is added for first person' do
        fm = Fabricate.build(:family_member)

        expect do
          fm.save
        end.to change(described_class, :count).by(2)

        inverse = described_class.find_by(
          person: fm.other,
          kind: 'sibling',
          other: fm.person,
          family_key: fm.family_key
        )

        expect(inverse).to be_present
      end

      it 'inverse relation is removed as well' do
        fm = Fabricate(:family_member)

        expect do
          fm.destroy
        end.to change(described_class, :count).by(-2)

        inverse = described_class.find_by(
          person: fm.other,
          kind: 'sibling',
          other: fm.person,
          family_key: fm.family_key
        )

        expect(inverse).to be_blank
      end

      it 'transitive relation is added when A is new sibling of B and C' do
        a = Fabricate(:person, nickname: 'Alice')
        b = Fabricate(:person, nickname: 'Bob')
        c = Fabricate(:person, nickname: 'Carol')

        Fabricate(:family_member, person: b, other: c)

        connections = [
          :new_sibling,
          :inversion_of_new_sibling,
          :transitive_to_sibling_of_sibling,
          :inversion_of_transitive_relation
        ]

        expect do
          described_class.new(person: a, other: b, kind: :sibling).save!
        end.to change(described_class, :count).by(connections.size) # 4

        expect(described_class.where(person: c, kind: :sibling).count).to eq 2
        expect(described_class.where(person: c, kind: :sibling).map(&:other)).to match_array [a, b]
      end

      it 'all sibling-ties are cut if one is no longer sibling of any other sibling' do
        a = Fabricate(:person, nickname: 'Alice')
        b = Fabricate(:person, nickname: 'Bob')
        c = Fabricate(:person, nickname: 'Carol')

        Fabricate(:family_member, person: b, other: c, kind: :sibling)
        Fabricate(:family_member, person: a, other: b, kind: :sibling)

        expect do
          described_class.where(person: a, kind: :sibling).each do |tie|
            tie.destroy
          end
        end.to change(described_class, :count).by(-4)
        # see "transitive relation is added when A is new sibling of B and C"
      end
    end
  end
end
