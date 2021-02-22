# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: settings
#
#  id          :bigint           not null, primary key
#  target_type :string(255)      not null
#  value       :text(65535)
#  var         :string(255)      not null
#  created_at  :datetime
#  updated_at  :datetime
#  target_id   :bigint           not null
#
# Indexes
#
#  index_settings_on_target_type_and_target_id          (target_type,target_id)
#  index_settings_on_target_type_and_target_id_and_var  (target_type,target_id,var) UNIQUE
#

require "spec_helper"

describe GroupSetting do
  let(:group) { groups(:top_layer) }
  let(:setting) do
    GroupSetting.new(var: "text_message_provider")
  end

  it "returns all possible group settings" do
    settings = GroupSetting.settings
    expect(settings.size).to eq(1)
    expect(settings.keys).to include("text_message_provider")
  end

  it "returns default value if present" do
    expect(setting.username).to be(nil)
    expect(setting.provider).to eq("aspsms")
  end

  it "does not return default value if value present" do
    setting.provider = "other"

    expect(setting.provider).to eq("other")
  end

  it "encrypts username, password" do
    setting.username = "david.hasselhoff"
    setting.password = "knightrider"
    setting.provider = "aspsms"
    value = setting.value

    expect(value).not_to include("username")
    expect(value).to include("encrypted_username")

    expect(value).not_to include("password")
    expect(value).to include("encrypted_password")

    expect(value).not_to include("encrypted_provider")
    expect(value).to include("provider")

    encrypted_password = value["encrypted_password"]
    expect(encrypted_password[:encrypted_value]).to be_present
    expect(encrypted_password[:iv]).to be_present
    expect(setting.password).to eq("knightrider")

    encrypted_username = value["encrypted_username"]
    expect(encrypted_username[:encrypted_value]).to be_present
    expect(encrypted_username[:iv]).to be_present
    expect(setting.username).to eq("david.hasselhoff")
  end
end
