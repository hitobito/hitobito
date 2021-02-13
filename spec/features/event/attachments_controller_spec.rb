# encoding: utf-8

#  Copyright (c) 2015, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::AttachmentsController do
  let(:group) { groups(:top_layer) }
  let(:event) { events(:top_event) }

  it "uploads file", js: true do
    sign_in
    visit group_event_path(group.id, event.id)

    file = Tempfile.new(["foo", ".pdf"])
    attach_file "event_attachment_file", file.path, visible: false

    expect(page).to have_selector("#attachments li", text: File.basename(file.path))
  end

  it "cannot upload unaccepted file", js: true do
    skip "Unable to find modal dialog"
    sign_in
    visit group_event_path(group.id, event.id)

    file = Tempfile.new(["foo", ".exe"])
    accept_alert(/fehlgeschlagen/) do
      attach_file "event_attachment_file", file.path, visible: false
    end

    expect(page).to have_no_selector("#attachments li", text: File.basename(file.path))
  end

  it "destroys existing file", js: true do
    file = Tempfile.new(["foo", ".png"])
    a = event.attachments.create!(file: file)
    sign_in
    visit group_event_path(group.id, event.id)

    accept_confirm do
      find("#event_attachment_#{a.id} a.action").click
    end

    expect(page).to have_no_selector("#attachments li", text: File.basename(file.path))
    expect(event.attachments.size).to eq(0)
  end
end
