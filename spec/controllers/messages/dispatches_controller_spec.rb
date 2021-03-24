# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::DispatchesController do
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context 'letter' do
    let(:message) { messages(:letter) }

    it 'POST#create redirects to assignments#new' do
      post :create, params: { message_id: message.id }
      expect(response).to redirect_to new_assignment_redirect_path(message)
      expect(flash[:alert]).to eq 'Sobald der Druckauftrag erstellt wurde, kann der Brief nicht mehr bearbeitet werden.'
    end
  end

  context 'letter with invoice' do
    let(:message) { messages(:with_invoice) }

    it 'POST#create redirects to assignments#new' do
      post :create, params: { message_id: message.id }
      expect(message.reload.invoice_list).to be_persisted
      expect(response).to redirect_to new_assignment_redirect_path(message)
      expect(flash[:alert]).to eq 'Sobald der Druckauftrag erstellt wurde, kann der Rechnungsbrief nicht mehr bearbeitet werden.'
    end
  end

  context 'text message' do
    let(:message) { messages(:sms) }
    let(:list) { message.mailing_list }

    it 'POST#create creates dispatch and enqueues job and redirects to message#show' do
      expect do
        post :create, params: { message_id: message.id }
      end.to change { Messages::DispatchJob.new(message).delayed_jobs.count }.by(1)
      expect(message.reload.state).to eq 'pending'
      expect(response).to redirect_to group_mailing_list_message_path(group_id: list.group.id, mailing_list_id: list.id, id: message.id)
      expect(flash[:notice]).to eq 'SMS wird versendet.'
    end
  end

  private

  def new_assignment_redirect_path(message)
    new_assignment_path(assignment: { attachment_id: message.id, attachment_type: 'Message'},
                        return_url: group_mailing_list_message_path(message.group,
                                                               message.mailing_list,
                                                               message)
                        )
  end
end
