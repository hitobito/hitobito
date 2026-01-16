#  frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.class MessageTemplate < ApplicationRecord

# == Schema Information
#
# Table name: message_templates
#
#  id             :bigint           not null, primary key
#  body           :text
#  templated_type :string
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  templated_id   :bigint
#
# Indexes
#
#  index_message_templates_on_templated  (templated_type,templated_id)
#
require "rails_helper"

describe MessageTemplate, type: :model do
  let(:message_template) { message_templates(:top_layer_one) }

  describe "#valid?" do
    it "validates presence of title" do
      message_template = described_class.new
      expect(message_template).not_to be_valid
      message_template.title = "New Title"
      expect(message_template).to be_valid
    end
  end

  describe "#option_for_select" do
    it "returns usable array" do
      expect(message_template.option_for_select).to eq([message_template.title, message_template.id,
        data: {title: message_template.title, body: message_template.body}])
    end
  end
end
