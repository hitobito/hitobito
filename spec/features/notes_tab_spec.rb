# frozen_string_literal: true

#  Copyright (c) 2025. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Notes tab", js: true do
  subject { page }

  before do
    sign_in
    visit help_texts_path
  end

  it 'should be able to display notes page after help text was created' do
    click_link "Erstellen"
    select "Notiz", from: "help_text_context"
    find('trix-editor').click.set('Notiz')
    click_button "Speichern"

    click_link "Gruppen"
    click_link "Notizen"
    expect(page).to have_text("Keine Einträge gefunden")
  end
end
