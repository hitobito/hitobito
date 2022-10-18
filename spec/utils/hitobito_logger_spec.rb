# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe HitobitoLogger do
  it '::categories returns allowed values' do
    expect(described_class.categories).to match_array %w[webhook ebics mail]
  end

  it '::levels returns allowed values' do
    expect(described_class.levels).to match_array %w[info error debug warn]
  end

  context 'log method' do
    it 'creates record with provided attrs' do
      expected_msg = "some\nmultiline\nmessage"
      expect {
        subject.send('info', 'ebics', expected_msg, subject: people(:bottom_member))
      }.to change {HitobitoLogEntry.count}.by(1)

      entry = HitobitoLogEntry.last
      expect(entry.level).to eq 'info'
      expect(entry.category).to eq 'ebics'
      expect(entry.message).to eq expected_msg
      expect(entry.subject).to eq people(:bottom_member)
    end

    it 'raises validation error with invalid params' do
      expect { subject.info('', '') }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  described_class.levels.each do |level|
    it "##{level} creates record with level=#{level}" do
      expect { subject.send(level, 'webhook', 'message') }.to change {HitobitoLogEntry.count}.by(1)
      expect(HitobitoLogEntry.last.level).to eq level
    end
  end
end
