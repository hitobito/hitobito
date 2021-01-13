# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::PreviewsController do
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context 'letter' do
    let(:message) { messages(:letter) }

    it 'redirects to message when recipients are empty' do
      get :show, params: { message_id: message.id }
      expect(response).to redirect_to message.path_args
      expect(flash[:alert]).to eq 'Empfängerliste ist leer, kann keine Vorschau erstellen.'
    end

    it 'renders file' do
      Subscription.create!(mailing_list: message.mailing_list, subscriber: top_leader)
      get :show, params: { message_id: message.id }
      expect(response.header['Content-Disposition']).to match(/information-preview.pdf/)
      expect(response.media_type).to eq('application/pdf')
    end

    context 'letter_with_invoice' do
      let(:message) { messages(:with_invoice) }

      it 'renders file' do
        invoice_configs(:top_layer).update(payment_slip: :qr)
        Subscription.create!(mailing_list: message.source, subscriber: top_leader)
        get :show, params: { message_id: message.id }
        expect(response.header['Content-Disposition']).to match(/rechnung-mitgliedsbeitrag-preview.pdf/)
        expect(response.media_type).to eq('application/pdf')
      end
    end
  end
end
