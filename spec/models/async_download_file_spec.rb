# frozen_string_literal: true

#  Copyright (c) 2022, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe AsyncDownloadFile do
  let(:raw_filename) { 'subscriptions to blørbaëls rants' }
  let(:person_id)    { 42 }
  let(:person)       { Person.new(id: person_id) }
  let(:other_person) { Person.new(id: 23) }

  let(:filename) { "subscriptions_to-blorbaels-rants_1651700845-#{person_id}" }
  let(:filetype) { 'txt' }
  let(:folder)   { Pathname.new(Settings.downloads.folder) }
  let(:data)     { SecureRandom.base64(128) }

  context 'on the class level, it' do
    subject { described_class }

    it 'creates filenames' do
      expect(
        subject.create_name(raw_filename, 42)
      ).to match(/^subscriptions-to-blorbaels-rants_\d+-42$/)
    end

    it 'parses created filenames' do
      parts = subject.parse_filename(
        'subscriptions_to-blorbaels-rants_1651700845-42'
      )

      expect(parts).to eql [
        'subscriptions_to-blorbaels-rants',
        '1651700845',
        '42'
      ]
    end

    it 'returns an instance from a filename' do
      result = subject.from_filename(
        'subscriptions_to-blorbaels-rants_1651700845-42', :txt
      )

      expect(result).to be_a described_class
      expect(result).to_not be_new_record
    end
  end

  context 'keep some parts of the AR-less interface, it' do
    subject { described_class.from_filename(filename, filetype) }

    it 'knows the passed filename' do
      expect(subject.filename).to eql "subscriptions_to-blorbaels-rants.#{filetype}"
    end

    it 'knows if the file is downloadable for a person' do
      file_double = double('attachement')
      expect(subject).to receive(:generated_file).and_return(file_double)
      expect(file_double).to receive(:attached?).and_return(true)

      expect(subject.downloadable?(person)).to be true
    end

    it 'allows write data to the filename' do
      expect do
        subject.write(data)
      end.to change(subject.generated_file, :attached?).from(false).to(true)
    end
  end

  it 'is not downloadable for a different person' do
    expect(subject.downloadable?(other_person)).to be false
  end
end
