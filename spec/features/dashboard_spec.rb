#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe :dashboard do
  let(:user) { people(:top_leader) }

  before { sign_in(user) }

  describe "/dashboard" do
    before do
      allow(FeatureGate).to receive(:enabled?).with("custom_dashboard_page").and_return(true)

      Fabricate(
        :custom_content,
        key: DashboardController::CUSTOM_DASHBOARD_PAGE_CONTENT,
        label: "Hitobito Startseite",
        subject: "Willkommen bei Hitobito",
        body: "<a href='#{events_path}'>Hier</a> findest du weitere Infos zu unseren Anlässen."
      )
    end

    it "renders custom dashboard page content" do
      visit dashboard_path

      expect(page).to have_selector "h1", text: "Willkommen bei Hitobito"
      expect(page).to have_link "Hier", href: events_path
      expect(page).to have_text "findest du weitere Infos zu unseren Anlässen."
    end
  end
end
