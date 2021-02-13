# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe RolesController, type: :controller do
  let(:test_entry) { roles(:bottom_member) }

  let(:new_entry_attrs) do
    {
      type: Group::BottomLayer::Member.sti_name
    }
  end

  let(:create_entry_attrs) do
    {
      label: "Materialchef",
      type: Group::BottomLayer::Member.sti_name,
      person_id: people(:top_leader).id
    }
  end

  let(:test_entry_attrs) do
    {
      type: Group::BottomLayer::Member.sti_name,
      label: "Materialchef"
    }
  end

  let(:group) { groups(:bottom_layer_one) }

  let(:scope_params) { {group_id: group.id} }

  # Override a few methods to match the actual behavior.
  class << self
    def it_should_redirect_to_show
      it do |example|
        if example.metadata[:action] == :create
          is_expected.to redirect_to group_people_path(group.id)
        else
          is_expected.to redirect_to group_person_path(group.id, entry.person_id)
        end
      end
    end

    def it_should_redirect_to_index
      it do
        path = Role.where(id: entry.id).exists? ? person_path(entry.person_id) : group_path(group)
        is_expected.to redirect_to path
      end
    end
  end

  include_examples "crud controller", skip: [%w(index), %w(show), %w(new plain)]

  let!(:user) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group).person }

  describe_action :get, :new do
    context ".html", format: :html do
      it "does not raise exception if no type is given" do
        expect(test_entry).to be_kind_of(Role)
      end

      it "chooses default role" do
        expect(response.body).to have_select("role_type", :selected => group.default_role.label)
      end

      context "with invalid type" do
        let(:params) { {role: {type: "foo"}} }

        it "raises exception", perform_request: false do
          expect { perform_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe_action :get, :edit, id: true do
    it "shows current role type rather than default" do
      expect(response.body).to have_select("role_type", :selected => "Member")
    end
  end

  context "using js" do
    before { sign_in(user) }

    let(:person) { Fabricate(:person) }

    it "new role for existing person returns new role" do
      post :create, xhr: true, params: {
        group_id: group.id,
        role: {group_id: group.id,
               person_id: person.id,
               type: Group::BottomLayer::Member.sti_name}}

      expect(response).to have_http_status(:ok)
      is_expected.to render_template("create")
      expect(response.body).to include("Bottom One")
    end

    it "creation of role without type returns error" do
      post :create, xhr: true, params: {
        group_id: group.id,
        role: {group_id: group.id, person_id: person.id}
      }

      expect(response).to have_http_status(:ok)
      is_expected.to render_template("create")
      expect(response.body).to include("alert")
    end
  end
end
