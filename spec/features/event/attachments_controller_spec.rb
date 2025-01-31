# frozen_string_literal: true

#  Copyright (c) 2015-2022, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::AttachmentsController, js: true do
  let(:group) { groups(:top_layer) }
  let(:event) { events(:top_event) }

  it "uploads file" do
    sign_in
    visit group_event_path(group.id, event.id)

    file = Tempfile.new(["foo", ".pdf"])
    attach_file "event_attachment_files", file.path, visible: false

    expect(page).to have_selector("#attachments tr", text: File.basename(file.path))
  end

  it "uploads multiple files" do
    sign_in
    visit group_event_path(group.id, event.id)

    file1 = Tempfile.new(["foo", ".pdf"])
    file2 = Tempfile.new(["foo", ".exe"])
    file3 = Tempfile.new(["foo", ".jpg"])

    accept_alert(/fehlgeschlagen/) do
      attach_file "event_attachment_files", [file1, file2, file3].map(&:path), visible: false
    end

    expect(page).to have_selector("#attachments tr", text: File.basename(file1.path))
    expect(page).to have_selector("#attachments tr", text: File.basename(file3.path))
  end

  it "cannot upload unaccepted file" do
    sign_in
    visit group_event_path(group.id, event.id)

    file = Tempfile.new(["foo", ".exe"])
    accept_alert(/fehlgeschlagen/) do
      attach_file "event_attachment_files", file.path, visible: false
    end

    expect(page).to have_no_selector("#attachments li", text: File.basename(file.path))
  end

  it "updates visibility" do
    file = Tempfile.new(["foo", ".png"])
    a = event.attachments.build
    a.file.attach(io: file, filename: "foo.png")
    a.visibility = :global
    a.save!
    sign_in
    visit group_event_path(group.id, event.id)

    selector = "#event_attachment_#{a.id} a.action .fa-globe:not(.icon-inactive)"
    find(selector).click

    expect(page).not_to have_selector(selector)
    expect(a.reload.visibility).to be_nil

    find("#event_attachment_#{a.id} a.action .fa-globe.icon-inactive").click

    expect(page).to have_selector(selector)
    expect(a.reload.visibility).to be("global")
  end

  it "destroys existing file" do
    event.attachments.delete_all
    file = Tempfile.new(["foo", ".png"])
    a = event.attachments.build
    a.file.attach(io: file, filename: "foo.png")
    a.save!
    sign_in
    visit group_event_path(group.id, event.id)

    accept_confirm do
      find("#event_attachment_#{a.id} a.action .fa-trash-alt").click
    end

    expect(page).to have_no_selector("#attachments li", text: File.basename(file.path))
    # expect(event.attachments.size).to eq(0) # this assertion is very flaky for some reason
  end
end
