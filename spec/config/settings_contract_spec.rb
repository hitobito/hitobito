# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs

require 'spec_helper'

describe SettingsContract do
  let(:settings) do
    {
      people: {
        inactivity_block: {
          warn_after: 'P1Y',
          block_after: 'P1Y'
        }
      }
    }
  end

  subject { described_class.new.call(settings) }

  context 'with valid settings' do
    it { is_expected.to be_success }
  end

  context 'people.inactivity_block' do
    it 'accepts nil values' do
      settings[:people][:inactivity_block][:warn_after] = nil
      settings[:people][:inactivity_block][:block_after] = nil

      is_expected.to be_success
    end

    context 'with invalid settings' do
      before do
        settings[:people][:inactivity_block][:warn_after] = 'invalid'
        settings[:people][:inactivity_block][:block_after] = 12345
      end

      it { is_expected.not_to be_success }

      it 'has the correct error message' do
        expect(subject.errors[:people][:inactivity_block][:warn_after])
          .to include('must be a valid ISO8601 duration string')
        expect(subject.errors[:people][:inactivity_block][:block_after])
          .to include('must be a string')
      end
    end
  end
end
