# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe HitobitoLogger do
  subject(:logger) { described_class.new }

  it '::categories returns allowed values' do
    expect(described_class.categories).to match_array %w[webhook ebics mail]
  end

  it '::levels returns allowed values' do
    expect(described_class.levels).to match_array %w[info error debug warn]
  end

  context '#log' do
    it 'creates record with provided attrs' do
      expected_msg = "some\nmultiline\nmessage"
      expected_payload = { foo: 'bar', hello: {beautiful: 'world'} }
      expect {
        logger.send(
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

  context '#unlog' do
    def unlog(level, category, message, subject)
      logger.send(:unlog, level, category, message, subject)
      logger.send(:unlog, level, category, message, subject)
    end

    let(:log_subject) { people(:bottom_member) }

    let!(:log_entry) do
      expect { logger.info('webhook', 'message', subject: log_subject, payload: {hello: :world}) }.
        to change {HitobitoLogEntry.count}.by(1)
      HitobitoLogEntry.last
    end

    it 'does not delete partially matching records' do
      expect { unlog('warn', 'webhook', 'message', log_subject) }.
        not_to change {HitobitoLogEntry.count}

      expect { unlog('info', 'email', 'message', log_subject) }.
        not_to change {HitobitoLogEntry.count}

      expect { unlog('info', 'webhook', 'another msg', log_subject) }.
        not_to change {HitobitoLogEntry.count}

      expect { unlog('info', 'webhook', 'message', people(:top_leader)) }.
        not_to change {HitobitoLogEntry.count}
    end

    it 'deletes all matching records' do
      another_duplicate_entry = HitobitoLogEntry.create!(log_entry.attributes.except('id', 'created_at'))

      expect { unlog('info', 'webhook', 'message', log_subject) }.
        to change {HitobitoLogEntry.count}.by(-2)

      expect { log_entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { another_duplicate_entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context '#log_replace' do
    it 'unlogs then logs' do
      level = 'info'
      category = 'webhook'
      message = 'message'
      subject = people(:bottom_member)
      payload = {hello: :world}

      expect(logger).to receive(:unlog).with(level, category, message, subject).ordered
      expect(logger).to receive(:log).with(level, category, message, subject, payload).ordered

      logger.send(:log_replace, level, category, message, subject, payload)
    end
  end

  described_class.levels.each do |level|
    it "##{level} calls log with level=#{level}" do
      expect(logger).to receive(:log).
        with(level, 'webhook', 'message', people(:bottom_member), {hello: :world})

      logger.send(level, 'webhook', 'message', subject: people(:bottom_member), payload: {hello: :world})
    end

    it "##{level}_replace calls log_replace with level=#{level}" do
      expect(logger).to receive(:log_replace).
        with(level, 'webhook', 'message', people(:bottom_member), {hello: :world})

      logger.send("#{level}_replace", 'webhook', 'message', subject: people(:bottom_member), payload: {hello: :world})
    end
  end
end
