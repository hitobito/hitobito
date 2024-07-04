# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Dropdown::Base do
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:dropdown) { Dropdown::Base.new(self, "my-dropdown", "my-icon") }
  let(:html) { Capybara::Node::Simple.new(dropdown.to_s) }

  it "renders link for item" do
    entry = groups(:bottom_layer_one)
    dropdown.add_item("the-item", entry)

    expect(html).to have_link("the-item", href: url_for(entry))
  end

  it "renders text for disabled item" do
    entry = groups(:bottom_layer_one)
    dropdown.add_item("the-item", entry, disabled_msg: "you-can-not-click-here")

    expect(html).not_to have_link(href: url_for(entry))
    expect(html).to have_selector 'a.disabled[title="you-can-not-click-here"]', text: "the-item"
  end
end
