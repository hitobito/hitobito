#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "devise/sessions/new.html.haml" do
  subject(:dom) { Capybara::Node::Simple.new(raw(rendered)) }

  let(:group) { groups(:top_group) }

  before do
    allow(view).to receive(:resource).and_return(Person.new)
    group.update!(self_registration_role_type: "Role::External")
  end

  it "does render helpful links" do
    render
    expect(dom).to have_link "Passwort vergessen", href: new_person_password_path
    expect(dom).to have_link "Keine Bestätigungs-E-Mail bekommen?", href: new_person_confirmation_path
    expect(dom).not_to have_link "Kein Account? Registrieren Sie sich hier.", href: group_self_registration_path(group)
  end

  it "includes signup link if a group is marked as main self registration group" do
    group.update!(main_self_registration_group: true)
    render
    expect(dom).to have_link "Kein Account? Registrieren Sie sich hier.", href: group_self_registration_path(group)
  end

  describe "oauth" do
    before { params[:oauth] = "true" }

    it "does render helpful links" do
      group.update!(main_self_registration_group: true)
      render
      expect(dom).to have_text "Bitte melde dich an, um weiter zu gelangen."
      expect(dom).to have_link "Passwort vergessen", href: new_person_password_path
      expect(dom).to have_link "Keine Bestätigungs-E-Mail bekommen?", href: new_person_confirmation_path
      expect(dom).to have_link "Kein Account? Registrieren Sie sich hier.", href: group_self_registration_path(group)
    end
  end
end
