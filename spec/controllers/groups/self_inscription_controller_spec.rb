# frozen_string_literal: true

#  Copyright (c) 2021, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Groups::SelfInscriptionController do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  context "with feature disabled" do
    before do
      group.update!(self_registration_role_type: Role::External.sti_name)
      allow(Settings.groups.self_registration).to receive(:enabled).and_return(false)
    end

    describe "GET show" do
      it "redirects to group if signed in" do
        sign_in(person)

        get :show, params: {group_id: group.id}

        is_expected.to redirect_to(group_person_path(group.id, person))
      end
    end

    it "redirects to group if group has registration disabled" do
      sign_in(person)
      group.update!(self_registration_role_type: "")

      get :show, params: {group_id: group.id}

      is_expected.to redirect_to(group_person_path(person.default_group_id, person))
    end
  end

  context "with feature enabled" do
    before do
      allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
    end

    context "GET show" do
      context "when registration active" do
        before do
          group.update(self_registration_role_type: Role::External.sti_name)
        end

        context "when unautorized" do
          it "renders page" do
            get :show, params: {group_id: group.id}

            is_expected.to redirect_to(new_person_session_path)
          end
        end

        context "when authorized" do
          before { sign_in(person) }

          it "redirects to self_inscription" do
            get :show, params: {group_id: group.id}

            is_expected.to render_template("groups/self_inscription/show")
          end

          context "when already member of the group" do
            before { Fabricate(:role, type: Role::External.sti_name, person: person, group: group) }

            it "redirects to group" do
              get :show, params: {group_id: group.id}

              is_expected.to redirect_to(group_person_path(group.id, person))
            end
          end
        end
      end

      context "when registration is inactive" do
        it "redirects to group" do
          sign_in(person)

          get :show, params: {group_id: group.id}

          is_expected.to redirect_to(group_person_path(group.id, person))
        end
      end
    end
  end
end
