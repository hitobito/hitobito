# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe QualificationsController do
  before { sign_in(person) }

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:params) { {group_id: group.id, person_id: person.id} }

  context "GET new" do
    it "builds entry for person" do
      get :new, params: params
      qualification = assigns(:qualification)
      expect(qualification.person).to eq person
    end
  end

  context "POST create" do
    let(:kind) { qualification_kinds(:gl) }

    it "redirects to show for person" do
      expect do
        post :create, params: params.merge(qualification: {qualification_kind_id: kind.id, start_at: Time.zone.now})
        is_expected.to redirect_to group_person_path(group, person)
      end.to change { Qualification.count }.by (1)
    end

    it "fails without permission" do
      sign_in(people(:bottom_member))
      expect do
        post :create, params: params.merge(qualification: {qualification_kind_id: kind.id, start_at: Time.zone.now})
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "POST destroy" do
    let(:id) { @qualification.id }

    before { @qualification = Fabricate(:qualification, person: person) }

    it "redirects to show for person" do
      expect do
        post :destroy, params: params.merge(id: id)
        is_expected.to redirect_to group_person_path(group, person)
      end.to change { Qualification.count }.by (-1)
    end

    it "fails without permission" do
      sign_in(people(:bottom_member))
      expect { post :destroy, params: params.merge(id: id) }.to raise_error(CanCan::AccessDenied)
    end
  end
end
