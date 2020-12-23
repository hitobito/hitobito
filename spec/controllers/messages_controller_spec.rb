# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe MessagesController do

  let(:top_leader) { people(:top_leader) }
  let(:list) { mailing_lists(:leaders) }
  let(:group) { list.group }

  before { sign_in(top_leader) }

  describe 'GET #new' do
    context 'message type' do
      it 'builds new text message if type text_message' do
        get :new, xhr: true, params: { group_id: group.id, mailing_list_id: list.id, type: 'text_message' }

        expect(assigns(:message).class).to eq(Messages::TextMessage)
      end

      it 'builds new letter if type letter' do
        get :new, xhr: true, params: { group_id: group.id, mailing_list_id: list.id, type: 'text_message' }

        expect(assigns(:message).class).to eq(Messages::TextMessage)
      end

      it 'raises error if invalid type' do
        expect do
          get :new, xhr: true, params: { group_id: group.id, mailing_list_id: list.id, type: 'bulk' }
        end.to raise_error('invalid message type provided')
      end

      it 'raises error if no type' do
        expect do
          get :new, xhr: true, params: { group_id: group.id, mailing_list_id: list.id }
        end.to raise_error('invalid message type provided')
      end
    end
  end

  describe 'POST #create' do
    context 'bulk mail' do
      it 'cannot create bulk mail' do
        message_params = { body: 'Einfach unmöglich!', type: Messages::BulkMail.sti_name }
        expect do
          post :create, params: { group_id: group.id, mailing_list_id: list.id,
                                  message: message_params }
        end.to raise_error('invalid message type provided')
      end
    end

    context 'text message' do
      it 'creates new text message' do
        message_params = { body: 'Dies ist eine fröhliche SMS :)', type: Messages::TextMessage.sti_name }
        expect do
          post :create, params: { group_id: group.id, mailing_list_id: list.id,
                                  message: message_params }
        end.to change { Messages::TextMessage.count }.by(1)

        message = list.text_messages.first
        expect(message.body).to match(/fröhliche SMS/)
      end
    end

    context 'letter' do
      it 'creates new letter' do
        message_params = { content: 'Dies ist ein fröhlicher Brief :)', type: Messages::Letter.sti_name }
        expect do
          post :create, params: { group_id: group.id, mailing_list_id: list.id,
                                  message: message_params }
        end.to change { Messages::Letter.count }.by(1)
      end
    end
  end
end
