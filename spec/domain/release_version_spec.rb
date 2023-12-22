# frozen_string_literal: true

#  Copyright (c) 2023-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_relative '../../app/domain/release_version'

describe ReleaseVersion do
  subject do
    sut = described_class.new

    allow(sut).to receive(:current_version).with(:production) do
      current_version
    end
    allow(sut).to receive(:days_since).with(current_version) do
      days_since
    end

    sut
  end
  let(:current_version) { '1.23.0' }
  let(:days_since) { 42 }

  context 'comes with assumptions and setup tweaks, it' do
    it 'has a stubbed out current version' do
      expect(subject.current_version(:production)).to eql '1.23.0'
    end

    it 'assumes 42 days since the last release' do
      expect(subject.days_since(current_version)).to eql 42
    end
  end

  context 'can suggest the next version, with style:' do
    it 'patch' do
      expect(subject.next_version(:patch)).to eql '1.23.1'
    end

    describe 'regular' do
      context 'with a minor-release within the last 7 days, it' do
        let(:days_since) { 5 }

        it 'keeps the current version' do
          expect(current_version).to eql '1.23.0'
          expect(subject.days_since('1.23.0')).to be <= 7
          expect(subject.next_version(:regular)).to eql '1.23.0'
        end
      end

      context 'with a patch-release within the last 7 days, it' do
        let(:days_since) { 5 }
        let(:current_version) { '1.23.1' }

        it 'keeps the current version' do
          expect(current_version).to eql '1.23.1'
          expect(subject.days_since('1.23.1')).to be <= 7
          expect(subject.next_version(:regular)).to eql '1.24.0'
        end
      end

      context 'with no release within the last 7 days, it' do
        let(:days_since) { 14 }

        it 'increments the minor version' do
          expect(current_version).to eql '1.23.0'
          expect(subject.days_since('1.23.0')).to be > 7
          expect(subject.next_version(:regular)).to eql '1.24.0'
        end
      end
    end

    it 'custom (with version)' do
      expect(subject.next_version(:custom, '98.SP3')).to eql '98.SP3'
    end
  end

  it 'can suggest the next integration-version' do
    expect(subject.next_integration_version).to eql '1.23.0-42'
  end
end
