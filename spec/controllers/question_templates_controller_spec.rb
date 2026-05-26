# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe QuestionTemplatesController do
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:ga_template) { event_question_templates(:ga_template) }
  let(:vegi_template) { event_question_templates(:vegi_template) }
  let(:schub_template) { event_question_templates(:schub_template) }

  render_views

  before { sign_in(person) }

  describe "GET index" do
    it "returns application and admin questions seperatly" do
      get :index, params: {group_id: group.id}
      expect(response).to be_successful
      expect(assigns(:application_entries)).to match_array([ga_template, vegi_template, schub_template])
      expect(assigns(:admin_entries)).to be_empty
    end
  end

  describe "GET new" do
    it "builds entry with application question" do
      get :new, params: {group_id: group.id, admin: false}
      expect(response).to be_successful
      expect(assigns(:question_template).question.admin).to be_falsey
    end

    it "builds entry with admin question" do
      get :new, params: {group_id: group.id, admin: true}
      expect(response).to be_successful
      expect(assigns(:question_template).question.admin).to be_truthy
    end
  end

  describe "GET edit" do
    it "raises access denied when question is not editable" do
      allow(Event::Question::Default).to receive(:template_editable).and_return(false)

      expect { get :edit, params: {group_id: group.id, id: ga_template.id} }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "POST create" do
    let(:params) do
      {
        group_id: group.id,
        event_question_template: {
          default: true,
          inherit: false,
          question_attributes: {
            question: "Test question",
            admin: true
          }
        }
      }
    end

    it "creates a new template" do
      expect { post :create, params: params }.to change(Event::QuestionTemplate, :count).by(1)
      expect(response).to redirect_to(group_question_templates_path(group))
    end
  end

  describe "PATCH update" do
    it "updates the template" do
      patch :update, params: {group_id: group.id, id: ga_template.id, event_question_template: {inherit: true}}
      expect(ga_template.reload.inherit).to be true
      expect(response).to redirect_to(group_question_templates_path(group))
    end

    it "raises access denied when question is not editable" do
      allow(Event::Question::Default).to receive(:template_editable).and_return(false)

      expect do
        patch :update, params: {group_id: group.id, id: ga_template.id, event_question_template: {inherit: true}}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "DELETE destroy" do
    it "destroys the template" do
      expect do
        delete :destroy, params: {group_id: group.id, id: ga_template.id}
      end.to change(Event::QuestionTemplate, :count).by(-1)
      expect(response).to redirect_to(group_question_templates_path(group))
    end

    it "raises access denied when question is not editable" do
      allow(Event::Question::Default).to receive(:template_editable).and_return(false)

      expect do
        delete :destroy, params: {group_id: group.id, id: ga_template.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
