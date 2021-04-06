# frozen_string_literal: true

require 'spec_helper'

describe MailingListMailsController do

  let(:top_leader) { people(:top_leader) }
  let(:params) { { uid: '20', mailbox: 'INBOX' } }
  let(:params_invalid) { { uid: '1', mailbox: 'INBOX' } }
  let(:params_move) { { uid: 2, from: 'INBOX', to: 'INBOX' } }
  let(:params_delete) { { ids: '1,2', mailbox: 'INBOX' } }


  let(:imap_connector) { double(:imap_connector) }

  before do
    sign_in(top_leader)
    allow(controller).to receive(:imap).and_return(imap_connector)

    # mocked methods, needs to be filled with arguments & return values
    # further, this is very relaxed, add following for stricter tests:
    # expect(imap_connector).to receive(:method).with(arguments).and_return(return_value)
    allow(imap_connector).to receive(:fetch_all).and_return([])
    allow(imap_connector).to receive(:fetch_by_uid).with(2, :inbox)
    allow(imap_connector).to receive(:move_by_uid)
    allow(imap_connector).to receive(:delete_by_uid)
    allow(imap_connector).to receive(:count)
    allow(imap_connector).to receive(:counts)

  end

  context 'GET index' do
    it 'can be accessed as admin' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'lists all mails when admin' do
      get :index

      expect(assigns(:mails)).to be_instance_of(Hash)

      assigns(:mails).each do |_, mails|
        expect(mails).to be_instance_of(Array)

        unless mails.empty?
          expect(mails).to all(be_instance_of(CatchAllMail))
        end
      end
    end

    it 'cannot be accessed as non-admin' do
      sign_in(people(:bottom_member))
      expect do
        get :index
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'PATCH move' do
    it 'can be accessed as admin' do
      patch :move, params: params_move
      expect(response).to have_http_status(:success)
    end

    xit 'redirects to index afterwards' do
      get :show, params: params
      expect(response).to redirect_to mailing_list_mail_path
    end

    it 'cannot be moved as non-admin' do
      expect do
        patch :move, params: params_move
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'DELETE destroy' do
    it 'can be accessed as admin' do
      delete :destroy, params: params_delete
      expect(response).to have_http_status(:success)
    end

    xit 'redirects to index afterwards' do
      delete :destroy, params: params_delete
      expect(response).to redirect_to mailing_list_mail_path
    end

    it 'cannot be deleted by non-admin' do
      sign_in(people(:bottom_member))
      expect do
        delete :destroy, params: params
      end.to raise_error(CanCan::AccessDenied)
    end
  end

end
