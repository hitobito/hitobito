# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe GroupSettingsController do

  let(:top_leader) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:setting_params) do
    { username: "gollum",
      password: "my-precious",
      provider: "aspsms" }
  end
  let(:setting) { group.settings(:text_message_provider) }

  before { sign_in(top_leader) }

  describe "POST #update" do
    it "initializes setting on first update" do
      patch :update, params: { group_id: group.id, id: "text_message_provider",
                               group_setting: setting_params }

      expect(setting.username).to eq("gollum")
      expect(setting.password).to eq("my-precious")
      expect(setting.provider).to eq("aspsms")
    end

    it "only concerns available attrs when updating" do
      setting_params[:gollum] = "smeagol"
      patch :update, params: { group_id: group.id, id: "text_message_provider",
                               group_setting: setting_params }

      expect(setting.gollum).to be_nil
    end

    it "updates existing setting" do
      group.settings(:text_message_provider).update!(setting_params)

      setting_params[:username] = "frodo"
      setting_params[:password] = "his-precious"

      patch :update, params: { group_id: group.id, id: "text_message_provider",
                               group_setting: setting_params }

      setting.reload
      expect(setting.username).to eq("frodo")
      expect(setting.password).to eq("his-precious")
      expect(setting.provider).to eq("aspsms")
    end

    it "does not clear password if blank value provided" do
      group.settings(:text_message_provider).update!(setting_params)

      setting_params[:username] = "frodo"
      setting_params[:password] = ""

      patch :update, params: { group_id: group.id, id: "text_message_provider",
                               group_setting: setting_params }

      setting.reload
      expect(setting.username).to eq("frodo")
      expect(setting.password).to eq("my-precious")
      expect(setting.provider).to eq("aspsms")
    end

    it "cannot update setting if no permission" do
      sign_in(people(:bottom_member))

      expect do
        patch :update, params: { group_id: group.id, id: "text_message_provider",
                                 group_setting: setting_params }
      end.to raise_error(CanCan::AccessDenied)
    end

    it "cannot create/update not configured setting" do
      expect do
        patch :update, params: { group_id: group.id, id: "non_existent",
                                 group_setting: setting_params }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #index" do
    it "lists all available settings for given group" do
      get :index, params: { group_id: group.id }

      settings = assigns(:setting_objects)
      expect(settings.count).to eq(1)
    end

    it "cannot list settings if no permission" do
      sign_in(people(:bottom_member))

      expect do
        get :index, params: { group_id: group.id }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

end
