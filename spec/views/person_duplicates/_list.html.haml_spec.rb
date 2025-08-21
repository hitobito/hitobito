#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "person_duplicates/_list.html.haml" do
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    assign(:group, Group.new(id: 1))
    allow(view).to receive(:entries).and_return(PersonDuplicate.none.page(1))
  end

  it "navigates outside of frame" do
    expect(dom).to have_css("turbo-frame#search_results[target=_top]")
  end
end
