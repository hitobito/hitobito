# frozen_string_literal: true

#  Copyright (c) 2023, Dachverband Schweizer Jugendparlamente. This file is part of
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Mailing List Subscriber Lists", js: true do
  include_context "people multiselect"

  let!(:list) { Fabricate(:mailing_list, name: "Newsletter", group: group) }

  shared_examples "subscriber actions" do
    before { open_people_list }

    it "subscribes selected people only" do
      click_link("Zu Abo hinzufügen")
      find("#q").fill_in with: "News"
      find('ul[role="listbox"] li[role="option"]', text: "Newsletter").click

      expect do
        click_button("Hinzufügen")
        expect(page).to have_content("#{count} Personen wurden erfolgreich zum Abo 'Newsletter' hinzugefügt")
      end.to change { Subscription.count }.by(count)

      expect(list.subscriptions.pluck(:subscriber_id)).to match_array(selected.map(&:id))
    end
  end

  context "with single people selected" do
    include_context "single people selected"

    it_behaves_like "subscriber actions"
  end

  context "with all filtered people selected" do
    include_context "all filtered people selected"

    it_behaves_like "subscriber actions"
  end
end
