#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FilterHelper do
  describe "#direct_filter_inline_checkbox" do
    let(:node) { Capybara::Node::Simple.new(direct_filter_inline_checkbox(:standalone, "Einzelrechnungen")) }

    it "renders an unchecked checkbox by default" do
      expect(node).to have_unchecked_field("standalone")
      expect(node).to have_content "Einzelrechnungen"
    end

    it "renders a checked checkbox when value is 1" do
      node = Capybara::Node::Simple.new(
        direct_filter_inline_checkbox(:standalone, "Einzelrechnungen", value: "1")
      )
      expect(node).to have_checked_field("standalone")
    end

    it "renders an unchecked checkbox when value is 0" do
      node = Capybara::Node::Simple.new(
        direct_filter_inline_checkbox(:standalone, "Einzelrechnungen", value: "0")
      )
      expect(node).to have_unchecked_field("standalone")
    end

    it "renders a hidden field so unchecking submits 0" do
      expect(node).to have_field("standalone", type: :hidden, with: "0")
    end
  end
end
