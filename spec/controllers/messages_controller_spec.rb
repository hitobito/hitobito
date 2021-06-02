# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MessagesController do
  let(:list)       { mailing_lists(:leaders) }
  let(:nesting)    { { group_id: list.group_id, mailing_list_id: list.id } }
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context 'GET#index' do
    it 'is present for current year' do
      get :index, params: nesting
      expect(assigns(:messages)).to be_present
    end

    it 'is empty for previous year' do
      travel_to 1.year.ago do
        get :index, params: nesting
      end
      expect(assigns(:messages)).to be_empty
    end
  end

  context 'GET#new' do
    before do
      Fabricate(:subscription, mailing_list: list, subscriber: top_leader)
    end

    it 'builds new Letter' do
      get :new, params: nesting.merge(message: { type: 'Message::Letter' })
      expect(assigns(:message)).to be_kind_of(Message::Letter)
    end

    it 'builds new LetterWithInvoice' do
      get :new, params: nesting.merge(message: { type: 'Message::LetterWithInvoice' })
      expect(assigns(:message)).to be_kind_of(Message::LetterWithInvoice)
    end
  end

  context 'POST#create' do
    it 'saves Letter' do
      post :create, params: nesting.merge(
        message: { subject: 'Mitgliedsbeitrag', body: 'body', type: 'Message::Letter' }
      )
      expect(assigns(:message)).to be_persisted
      expect(response).to redirect_to group_mailing_list_message_path(id: assigns(:message).id)
    end

    it 'saves LetterWithInvoice with invoice_items attributes' do
      Subscription.create!(mailing_list: list, subscriber: top_leader)

      post :create, params: nesting.merge(
        message: {
          subject: 'Mitgliedsbeitrag',
          type: 'Message::LetterWithInvoice',
          body: 'Bitte einzahlen',
          invoice_attributes: {
            invoice_items_attributes: {
              '1' => { 'name' => 'Mitgliedsbeitrag', 'unit_cost' => 42, '_destroy' => 'false' }
            }
          }
        }
      )
      expect(assigns(:message)).to be_persisted
      expect(assigns(:message).invoice.invoice_items.first.name).to eq 'Mitgliedsbeitrag'
      expect(response).to redirect_to group_mailing_list_message_path(id: assigns(:message).id)
    end

    it 'keeps invoice_items attributes if missing body for LetterWithInvoice' do
      post :create, params: nesting.merge(
        message: {
          subject: 'Mitgliedsbeitrag',
          type: 'Message::LetterWithInvoice',
          invoice_attributes: {
            invoice_items_attributes: {
              '1' => { 'name' => 'Mitgliedsbeitrag', 'unit_cost' => 42, '_destroy' => 'false' }
            }
          }
        }
      )
      expect(assigns(:message)).to be_invalid
      expect(assigns(:message).invoice.invoice_items.first.name).to eq 'Mitgliedsbeitrag'
      expect(response).to render_template :new
    end

    it 'validates invoice_item attributes' do
      post :create, params: nesting.merge(
        message: {
          subject: 'Mitgliedsbeitrag',
          body: 'Very good price!',
          type: 'Message::LetterWithInvoice',
          invoice_attributes: {
            invoice_items_attributes: {
              '1' => { 'name' => '', 'unit_cost' => '', '_destroy' => 'false' }
            }
          }
        }
      )
      expect(assigns(:message)).to be_invalid
      expect(response).to render_template :new
    end

    it 'creates Text Message' do
      post :create, params: nesting.merge(
        message: { text: 'Long live SMS!', type: 'Message::TextMessage' }
      )
      expect(assigns(:message)).to be_persisted
      expect(response).to redirect_to group_mailing_list_message_path(id: assigns(:message).id)
    end

  end

  context 'preview' do
    let(:bottom_member) { people(:bottom_member) }

    context 'letter' do
      let(:message) { messages(:letter) }

      it 'redirects to message when recipients are empty' do
        get :show, format: :pdf, params: { preview: true, id: message.id, mailing_list_id: message.mailing_list.id, group_id: message.mailing_list.group.id }
        expect(response).to redirect_to message.path_args
        expect(flash[:alert]).to eq 'Empfängerliste ist leer, kann kein PDF erstellen.'
      end

      it 'renders file' do
        expect(Export::Pdf::Messages::Letter).to receive(:new).with(anything, anything, background: Settings.messages.pdf.preview).and_call_original
        Subscription.create!(mailing_list: message.mailing_list, subscriber: bottom_member)
        get :show, format: :pdf, params: { preview: true, id: message.id, mailing_list_id: message.mailing_list.id, group_id: message.mailing_list.group.id }
        expect(response.header['Content-Disposition']).to match(/preview-information.pdf/)
        expect(response.media_type).to eq('application/pdf')
      end
    end

    context 'letter_with_invoice' do
      let(:message) { messages(:with_invoice) }

      it 'renders file' do
        invoice_configs(:top_layer).update(payment_slip: :qr)
        Subscription.create!(mailing_list: message.mailing_list, subscriber: bottom_member)
        get :show, format: :pdf, params: { preview: true, id: message.id, mailing_list_id: message.mailing_list.id, group_id: message.mailing_list.group.id }
        expect(response.header['Content-Disposition']).to match(/preview-rechnung-mitgliedsbeitrag.pdf/)
        expect(response.media_type).to eq('application/pdf')
      end
    end
  end
end
