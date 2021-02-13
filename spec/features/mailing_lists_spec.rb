#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailingListsController, js: true do
  let(:user) { people(:top_leader) }
  let(:list) { mailing_lists(:leaders) }

  before { sign_in }

  it "removes two labels from existing mailing" do
    list.update(preferred_labels: %w(Mutter Vater))
    visit edit_group_mailing_list_path(list.group, list)

    all("span.chip a")[0].click
    find(".btn-toolbar.top button[type=submit]").click
    expect(page).not_to have_content "Mutter"

    visit edit_group_mailing_list_path(list.group, list)
    all("span.chip a")[0].click
    find(".btn-toolbar.top button[type=submit]").click
    expect(page).not_to have_content "Vater"
  end

  it "adds single label to new mailing list" do
    visit new_group_mailing_list_path(list.group)
    fill_in "Name", with: "test"

    find(".chip-add").click
    fill_in id: "label", with: "Vater"
    page.find("body").click # blur
    expect(page).to have_content "Vater"

    find(".btn-toolbar.top button[type=submit]").click

    expect(page).to have_content "Vater"
  end

  it "adds two preferred_labels to existing mailing list" do
    visit edit_group_mailing_list_path(list.group, list)

    find(".chip-add").click
    fill_in id: "label", with: "Vater"
    page.find("body").click # blur
    expect(page).to have_content "Vater"

    find(".chip-add").click
    fill_in id: "label", with: "Mutter"
    page.find("body").click # blur
    expect(page).to have_content "Mutter"

    find(".btn-toolbar.top button[type=submit]").click

    expect(page).to have_content "Mutter, Vater"
  end
end
