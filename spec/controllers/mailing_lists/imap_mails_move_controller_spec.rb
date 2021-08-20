#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

require 'net/imap'

describe MailingLists::ImapMailsMoveController do
  include MailingLists::ImapMailsHelper

  let(:top_leader) { people(:top_leader) }

  let(:imap_connector) { double(:imap_connector) }

  let(:imap_mail_1) { new_imap_mail }
  let(:imap_mail_2) { new_imap_mail(false) }
  let(:imap_mail_data) { [imap_mail_1, imap_mail_2] }

  let(:now) { Time.zone.now }

  before do
    email = double
    retriever = double
    config = double('config',
                    address: 'imap.example.com',
                    imap_port: 995,
                    enable_ssl: true,
                    user_name: 'catch-all@example.com',
                    password: 'holly-secret')
    allow(Settings).to receive(:email).and_return(email)
    allow(email).to receive(:retriever).and_return(retriever)
    allow(retriever).to receive(:config).and_return(config)
  end

  context 'PATCH #create' do
    it 'moves Mail to given mailbox' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector).twice

      expect(imap_connector).to receive(:move_by_uid).with(42, :inbox, :failed)
      expect(imap_connector).to receive(:move_by_uid).with(43, :inbox, :failed)

      patch :create, params: { mailbox: 'inbox', ids: '42,43', dst_mailbox: 'failed' }

      expect(flash[:notice]).to include '2 Mails erfolgreich verschoben'
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to imap_mails_path
    end

    it 'returns inbox if given mailbox is invalid' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector).to receive(:move_by_uid).with(42, :inbox, :inbox)

      patch :create, params: { mailbox: 'inbox', ids: '42', dst_mailbox: 'invalid_mailbox' }

      expect(flash[:notice]).to include 'Mail erfolgreich verschoben'
      expect(response).to have_http_status(:found)
      expect(response.location).to eq('http://test.host/mailing_lists/imap_mails/inbox')
    end

    it 'does not allow non-admins to move mails' do
      sign_in(people(:bottom_member))

      expect(controller).to receive(:imap).never

      expect do
        patch :create, params: { mailbox: 'inbox', ids: '42' }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'displays flash notice if mail server not reachable' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector)
        .to receive(:move_by_uid)
        .with(42, :inbox, :failed)
        .and_raise(Net::IMAP::NoResponseError, ImapMoveErrorDataDouble)

      patch :create, params: { mailbox: 'inbox', ids: '42', dst_mailbox: 'failed' }

      expect(response).to have_http_status(:redirect)

      expect(flash[:notice])
        .to eq(["Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut.", "Authentication failed."])
    end

    it 'cannot move mails from failed mailbox' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector).never

      expect do
        patch :create, params: { mailbox: 'failed', ids: '42', mail_dst: 'inbox' }
      end.to raise_error('failed mails cannot be moved')
    end

  end

  private

  # and_raise only accepts either String or Module
  # so creating a double with a Module
  module ImapMoveErrorDataDouble
    Data = Struct.new(:text)
    def self.data
      data = Data.new('Authentication failed.')
      data
    end
  end

end
