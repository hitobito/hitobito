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
      expected_payload = { foo: 'bar', hello: {beautiful: 'world'} }
      expect {
        subject.send(
          'info',
          'ebics',
          expected_msg,
          subject: people(:bottom_member),
          payload: expected_payload
        )
      }.to change {HitobitoLogEntry.count}.by(1)

      expect(HitobitoLogEntry.last).to have_attributes(
        level: 'info',
        category: 'ebics',
        message: expected_msg,
        payload: expected_payload.deep_stringify_keys,
        subject: people(:bottom_member)
      )
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
