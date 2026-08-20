# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "groups/_confirm_deletion.html.haml" do
  let(:group) { groups(:bottom_group_one_two) }
  let(:dom) { Capybara::Node::Simple.new(@rendered) }

  before do
    allow(view).to receive(:entry).and_return(group)
    @rendered = render(partial: "groups/confirm_deletion")
  end

  it "renders the confirmation modal and delete action" do
    expect(dom).to have_css("#confirm-group-deletion")
    expect(dom.find("#confirm-group-deletion")["data-controller"]).to eq("confirm-deletion")
    expect(dom.find("#confirm-group-deletion")["data-confirm-deletion-expected-value"]).to eq(group.name)
    expect(dom).to have_css("h5.modal-title", text: t("groups.confirm_deletion.title", group_name: group.name))
    expect(dom).to have_css("input[name='group-name'][data-action='confirm-deletion#validate']")
    expect(dom).to have_link(t("groups.confirm_deletion.delete"), href: group_path(group))
    expect(dom).to have_css("a.btn-danger[data-method='delete']")
    expect(dom).to have_css("a.link.cancel", text: "Abbrechen")
  end
end
