# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Healthz::MailController do
  include MailingLists::ImapMailsSpecHelper

  describe 'GET show' do

    let(:json) { JSON.parse(response.body) }
    let(:token) { AppStatus.auth_token }
    let(:imap_mail) { build_imap_mail }
    let(:cache) { Rails.cache }
    let(:seen_mail) { AppStatus::Mail::SeenMail.build(imap_mail) }

    before { cache.write(:app_status, nil) }
    after { cache.write(:app_status, nil) }

    let(:imap_connector) { double(:imap_connector) }

    before do
      allow_any_instance_of(AppStatus::Mail).to receive(:imap).and_return(imap_connector)
    end

    context 'when there is no problem with mail services' do

      it 'has HTTP status 200' do

        eleven_minutes_ago = DateTime.now - 11.minutes

        seen_mail.first_seen = eleven_minutes_ago
        app_status = { seen_mails: [ seen_mail ] }
        cache.write(:app_status, app_status)

        expect(imap_connector)
          .to receive(:fetch_mails)
          .with(:inbox)
          .and_return([imap_mail])

        get :show, params: { token: token }

        expect(response.status).to eq(200)

        expect(json).to eq('app_status' => { 'code' => 'ok', 'details' => { 'catch_all_inbox' => 'ok' } })

      end

    end

    context 'when the mail services are not working properly' do

      it 'has HTTP status 503' do

        one_hour_ago = DateTime.now - 1.hour

        seen_mail.first_seen = one_hour_ago
        app_status = { seen_mails: [ seen_mail ] }
        cache.write(:app_status, app_status)

        expect(imap_connector)
          .to receive(:fetch_mails)
          .with(:inbox)
          .and_return([imap_mail])

        get :show, params: { token: token }

        expect(response.status).to eq(503)

        expect(json).to eq('app_status' => { 'code' => 'service_unavailable',
                                             'details' => { 'catch_all_inbox' => 'catch-all mailbox contains overdue mails. please make sure delayed job worker is running and no e-mail is blocking the queue/job.' } })

      end

    end

    context 'auth token' do

      it 'denies access if no auth token given' do

        get :show

        expect(response.status).to eq(401)

      end

      it 'denies access if wrong auth token given' do

        get :show, params: { token: 'wrong token' }

        expect(response.status).to eq(401)

      end

    end

  end


end
