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

end
