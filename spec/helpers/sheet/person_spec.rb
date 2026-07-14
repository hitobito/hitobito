# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Sheet::Person do
  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }
  let(:view) { double("view", can?: false) }
  let(:sheet) { described_class.new(view, nil, person) }

  describe "messages tab" do
    it "is shown when user can index_messages on person" do
      allow(view).to receive(:can?).with(:index_messages, person).and_return(true)

      labels = sheet.send(:visible_tabs).map(&:label)
      expect(labels).to include("Nachrichten")
    end

    it "is hidden when user cannot index_messages on person" do
      allow(view).to receive(:can?).with(:index_messages, person).and_return(false)

      labels = sheet.send(:visible_tabs).map(&:label)
      expect(labels).not_to include("Nachrichten")
    end
  end
end
