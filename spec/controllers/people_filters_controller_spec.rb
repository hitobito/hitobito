# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeopleFiltersController do

  before { sign_in(user) }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:role_types) { [Group::TopGroup::Leader, Group::TopGroup::Member] }
  let(:role_type_ids) { role_types.collect(&:id) }
  let(:role_type_ids_string) { role_type_ids.join(Person::Filter::Base::ID_URL_SEPARATOR) }
  let(:role_type_names) { role_types.collect(&:sti_name) }

  context "GET new" do
    it "builds entry with group and existing params" do
      get :new, params: { group_id: group.id, filters: { role: { role_type_ids: role_type_ids_string } } }

      filter = assigns(:people_filter)
      expect(filter.group).to eq(group)
      expect(assigns(:qualification_kinds)).to be_present
    end

    context "#possible_tags" do
      it "preloads available tags" do
        get :new, params: { group_id: group.id }
        expect(assigns(:possible_tags)).to eq []
      end

      it "translates invalid e-mail tags" do
        allow(Truemail).to receive(:valid?).and_call_original
        user.email = "not-an-email"
        user.save!(validate: false)
        AdditionalEmail
          .new(contactable: user,
               email: "mail@nodomain")
          .save!(validate: false)
        Contactable::EmailValidator.new.validate_people

        get :new, params: { group_id: group.id }
        invalid_email_tags = [["Haupt-E-Mail ungültig", "category_validation:email_primary_invalid", PersonTags::Validation.email_primary_invalid.id],
                              ["Weitere E-Mail ungültig", "category_validation:email_additional_invalid", PersonTags::Validation.email_additional_invalid.id]]

        tags = assigns(:possible_tags)
        expect(tags.count).to eq(2)
        invalid_email_tags.each do |t|
          expect(tags).to include(t)
        end
      end
    end
  end

  context "POST create" do
    it "redirects to show for search" do
      expect do
        post :create, params: { group_id: group.id, filters: { role: { role_type_ids: role_type_ids } }, button: "search" }
      end.not_to change { PeopleFilter.count }

      is_expected.to redirect_to(group_people_path(group, filters: { role: { role_type_ids: role_type_ids_string} }, range: "deep"))
    end

    it "redirects to show for empty search" do
      expect do
        post :create, params: {group_id: group.id, button: "search", people_filter: {}, filters: { qualification: { validity: "active" }}}
      end.not_to change { PeopleFilter.count }

      is_expected.to redirect_to(group_people_path(group))
    end

    it "saves filter and redirects to show with save" do
      expect do
        post :create, params: { group_id: group.id, filters: { role: { role_type_ids: role_type_ids } }, range: "deep", name: "Test Filter", button: "save" }
        expect(assigns(:people_filter)).to be_valid
        is_expected.to redirect_to(group_people_path(group, filter_id: assigns(:people_filter).id))
      end.to change { PeopleFilter.count }.by(1)
    end

    context "with read only permissions" do
      before do
        @role = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
        @person = @role.person
        sign_in(@person)
      end

      let(:group) { @role.group }

      it "redirects to show with search" do
        expect do
          post :create, params: { group_id: group.id, filters: { role: { role_type_ids: role_type_ids } }, button: "search" }
        end.not_to change { PeopleFilter.count }

        is_expected.to redirect_to(group_people_path(group, filters: { role: { role_type_ids: role_type_ids_string } }, range: "deep"))
      end

      it "is not authorized with save" do
        expect do
          post :create, params: { group_id: group.id, filters: { role: { role_type_ids: role_type_ids } }, name: "Test Filter", button: "save" }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

end
