# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe BulkMailRetriever do
  let(:connector) { described_class.new }
  let(:imap_connector) { double(:imap_connector) }
  let(:mailing_list) { mailing_lists(:leaders) }

  it 'receives mail and dispatches to mailing list' do
    imap_mails = []
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id)

    expect do
      expect do
        connector.perform
      end.to change { mailing_list.messages.count }.by(1)
    end.to change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)

    message = mailing_list.messages.first
    expect(message.subject).to eq('Supermail report')
    expect(message.sender).to eq('superman')
  end

  it 'terminates if imap server not reachable' do

  end

  it 'drops mail if cannot be assigned to mailing list' do

  end

  it 'raises exception if unknown error' do

  end
end


# keine neuen Mails
# neue, abozugehörige Mails
# nicht-abozugehörige Mails
# IMAP Server down
# unbekannter Fehler
