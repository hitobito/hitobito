# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::PrivacyPolicyFinder do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  subject(:policy_finder) { described_class.new(group, person) }

  context 'without privacy policy' do
    it '#groups are empty' do
      expect(policy_finder.groups).to be_empty
    end

    it '#acceptance_needed? is false' do
      expect(policy_finder).not_to be_acceptance_needed
    end
  end

  context 'with privacy policy' do
    before do
      file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
      image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, 'rb'),
                                                     filename: 'logo.png',
                                                     content_type: 'image/png').signed_id
      group.layer_group.update(privacy_policy: image)
    end

    it '#groups contains layer group' do
      expect(policy_finder.groups).to eq([group.layer_group])
    end

    describe '#acceptance_needed?' do
      it 'is true if person has not yet accepted' do
        expect(policy_finder).to be_acceptance_needed
      end

      it 'is true if person is accepting right now' do
        person.privacy_policy_accepted = true
        expect(policy_finder).to be_acceptance_needed
      end

      it 'is false if already has already accepted' do
        person.update!(privacy_policy_accepted: true)
        expect(policy_finder).not_to be_acceptance_needed
      end

      context 'non persisted person' do
        let(:person) { Fabricate.build(:person) }

        it 'is true if person has not yet accepted' do
          expect(policy_finder).to be_acceptance_needed
        end

        it 'is true if person is accepting' do
          person.privacy_policy_accepted = true
          expect(policy_finder).to be_acceptance_needed
        end
      end
    end
  end
end
