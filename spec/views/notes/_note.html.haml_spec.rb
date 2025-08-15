#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "notes/_note.html.haml" do
  let(:person) { people(:bottom_member) }
  let(:current_user) { person }
  let(:group) { groups(:top_layer) }
  let(:note) { Fabricate(:note, subject: people(:top_leader)) }

  before do
    allow(controller).to receive(:current_user).and_return(current_user)
    assign(:group, group)
  end

  it "displays profile picture" do
    expect(render(locals: {note: note, show_subject: true})).to have_css(".note-image")
    # rubocop:todo Layout/LineLength
    expect(rendered).to have_selector("img.note-image[src='/packs-test/media/images/profile-c150952c7e2ec2cf298980d55b2bcde3.svg']")
    # rubocop:enable Layout/LineLength
  end
end
