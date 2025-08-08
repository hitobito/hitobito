#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "groups/_actions_show.html.haml" do
  let(:group) { groups(:top_layer) }
  let(:dom) { Capybara::Node::Simple.new(@rendered) }

  before do
    assign(:group, group)
    allow(view).to receive_messages(entry: group)
    allow(controller).to receive_messages(current_user: current_user)
  end

  let(:dom) { Capybara::Node::Simple.new(@rendered) }

  context "address sync" do
    let(:current_user) { people(:top_leader) }

    it "hides button if config file is missing" do
      allow(Synchronize::Addresses::SwissPost::Config).to receive(:exist?).and_return(false)
      render
      expect(dom).not_to have_link "Adressensync"
    end

    it "renders button if config file is present" do
      allow(Synchronize::Addresses::SwissPost::Config).to receive(:exist?).and_return(true)
      render
      expect(dom).to have_link "Adressenabgleich", href: group_addresses_sync_path(group)
      expect(dom.find_link("Adressenabgleich")["data-method"]).to eq "post"
      within(dom.find_link("Adressenabgleich")) do
        expect(dom).to have_css("i.fas.fa-address-book")
      end
    end

    context "as bottom member" do
      let(:current_user) { people(:bottom_member) }

      it "hides button if config file exists file is missing" do
        allow(Synchronize::Addresses::SwissPost::Config).to receive(:exist?).and_return(true)
        render
        expect(dom).not_to have_link "Addressenabgleich"
      end
    end
  end
end
