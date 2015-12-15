# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::AddRequestsController do

  before { sign_in(user) }
  let(:group) { groups(:top_layer) }
  let(:user) { people(:top_leader) }

  describe 'GET index' do

    context 'status notification' do

      it 'shows nothing if no params passed' do
        get :index, group_id: group.id

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank
      end

      it 'shows nothing if not all params passed' do
        get :index, group_id: group.id, person_id: 42, body_id: 10

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank
      end

      it 'shows nothing if person_id not in layer' do
        get :index,
            group_id: group.id,
            person_id: people(:bottom_member).id,
            body_id: groups(:top_group).id,
            body_type: 'Group'

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank
      end

      it 'shows approved message if role exists' do
        get :index,
            group_id: group.id,
            person_id: people(:top_leader).id,
            body_id: groups(:top_group).id,
            body_type: 'Group'

        expect(flash[:notice]).to match(/freigegeben/)
        expect(flash[:alert]).to be_blank
      end

      it 'shows rejected message if role does not exist' do
        get :index,
            group_id: group.id,
            person_id: people(:top_leader).id,
            body_id: groups(:top_layer).id,
            body_type: 'Group'

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to match(/abgelehnt/)
      end

      it 'assigns current if request exists' do
        request = Person::AddRequest::Group.create!(
          person: people(:top_leader),
          body: groups(:top_layer),
          role_type: Group::TopLayer::TopAdmin.sti_name,
          requester: people(:bottom_member)
        )

        get :index,
            group_id: group.id,
            person_id: people(:top_leader).id,
            body_id: groups(:top_layer).id,
            body_type: 'Group'

        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank

        expect(assigns(:current)).to eq(request)
      end
    end
  end

  context 'POST activate' do
    let(:other_group) { groups(:bottom_layer_one) }

    it 'activates person add requests requirement if user has write permissions' do
      post :activate, group_id: group.id

      expect(group.reload.require_person_add_requests).to be true
      expect(flash[:notice]).to match(/aktiviert/)
    end

    it 'access denied when trying to activate for other group' do
      expect do
        post :activate, group_id: other_group.id
      end.to raise_error(CanCan::AccessDenied)
    end

  end

  context 'DELETE deactivate' do

    before { group.update_attribute(:require_person_add_requests, true) }
    let(:other_group) { groups(:bottom_layer_one) }

    it 'deactivates person add requests requirement if user has write permissions' do
      delete :deactivate, group_id: group.id

      expect(group.reload.require_person_add_requests).to be false
      expect(flash[:notice]).to match(/deaktiviert/)
    end

    it 'access denied when trying to deactivate for other group' do
      expect do
        delete :deactivate, group_id: other_group.id
      end.to raise_error(CanCan::AccessDenied)
    end

  end

  context 'DELETE reject' do

    let(:request) do
      Person::AddRequest::Group.create!(
        person: people(:top_leader),
        requester: people(:bottom_member),
        body: group,
        role_type: group.class.role_types.first.sti_name)
    end

    before { request } # create

    it 'removes the given request' do
      expect { delete :reject, id: request.id }.
        to change { Person::AddRequest::Group.count }.by(-1)
      expect(flash[:notice]).to match(/abgelehnt/)
      is_expected.to redirect_to(person_path(request.person))
    end

    context 'as requester' do
      let(:user) { people(:bottom_member) }

      it 'removes the given request' do
        expect { delete :reject, id: request.id, cancel: true }.
          to change { Person::AddRequest::Group.count }.by(-1)
        expect(flash[:notice]).to match(/zurückgezogen/)
      end
    end

  end

end
