# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe SelfRegistrationReasonsController do
  before { sign_in(person) }

  let(:entry) { self_registration_reasons(:the_best) }

  describe 'with necessary permissions' do
    let(:person) { people(:root) }

    context 'POST #create' do
      it 'creates entry' do
        expect do
          post :create, params: { self_registration_reason: { text: 'foo' }}
        end.to change { SelfRegistrationReason.count }.by(1)
      end
    end

    context 'PATCH #update' do
      it 'updates entry' do
        expect do
          patch :update, params: { id: entry.id, self_registration_reason: { text: 'foo' }}
        end.to change { entry.reload.text }.to('foo')
      end
    end

    context 'DELETE #destroy' do
      it 'deletes entry' do
        expect do
          delete :destroy, params: { id: entry.id }
        end.to change { SelfRegistrationReason.count }.by(-1)
      end

      it 'does not delete referenced entry' do
        Fabricate(:person, self_registration_reason: entry)
        expect do
          delete :destroy, params: { id: entry.id }
        end.not_to change { SelfRegistrationReason.count }
      end
    end
  end

  describe 'without admin permissions' do
    let(:person) { people(:bottom_member) }

    context 'POST #create' do
      it 'creates entry' do
        expect do
          post :create, params: { self_registration_reason: { text: 'foo' }}
        end.to raise_error CanCan::AccessDenied
      end
    end

    context 'PATCH #update' do
      it 'updates entry' do
        expect do
          patch :update, params: { id: entry.id, self_registration_reason: { text: 'foo' }}
        end.to raise_error CanCan::AccessDenied
      end
    end

    context 'DELETE #destroy' do
      it 'deletes entry' do
        expect do
          delete :destroy, params: { id: entry.id }
        end.to raise_error CanCan::AccessDenied
      end
    end

    context 'GET #index' do
      it 'does not list entries' do
        expect do
          get :index
        end.to raise_error CanCan::AccessDenied
      end
    end

    context 'GET #show' do
      it 'does not show entry' do
        expect do
          get :show, params: { id: entry.id }
        end.to raise_error CanCan::AccessDenied
      end
    end

  end

end
