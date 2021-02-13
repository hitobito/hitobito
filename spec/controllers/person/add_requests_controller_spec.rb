# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::AddRequestsController do

  before { sign_in(user) }
  let(:group) { groups(:top_layer) }
  let(:user) { people(:top_leader) }

  context "POST approve" do

    let!(:request) do
      Person::AddRequest::Group.create!(
        person: people(:top_leader),
        requester: people(:bottom_member),
        body: group,
        role_type: group.class.role_types.first.sti_name)
    end

    it "removes the given request" do
      expect { post :approve, params: { id: request.id } }.
        to change { Person::AddRequest::Group.count }.by(-1)
      expect(flash[:notice]).to match(/freigegeben/)
      is_expected.to redirect_to(person_path(request.person))
      expect(people(:top_leader).reload.roles.any? { |r| r.type == request.role_type }).to be_truthy
    end

  end

  context "DELETE reject" do

    let!(:request) do
      Person::AddRequest::Group.create!(
        person: people(:top_leader),
        requester: people(:bottom_member),
        body: group,
        role_type: group.class.role_types.first.sti_name)
    end

    it "removes the given request" do
      expect { delete :reject, params: { id: request.id } }.
        to change { Person::AddRequest::Group.count }.by(-1)
      expect(flash[:notice]).to match(/abgelehnt/)
      is_expected.to redirect_to(person_path(request.person))
    end

    context "as requester" do
      let(:user) { people(:bottom_member) }

      it "removes the given request" do
        expect { delete :reject, params: { id: request.id, cancel: true } }.
          to change { Person::AddRequest::Group.count }.by(-1)
        expect(flash[:notice]).to match(/zurückgezogen/)
      end
    end

  end

end
