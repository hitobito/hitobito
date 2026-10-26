# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Dropdown::PeopleLogin do
  include FormatHelper
  include LayoutHelper
  include UtilityHelper
  include I18nHelper

  let(:current_user) { people(:top_leader) }
  let(:ability) { Ability.new(current_user) }
  let(:parent) { person.primary_group }
  let(:send_login_tooltip_text) { "" }

  subject(:html) { Capybara::Node::Simple.new(described_class.new(self, person).to_s) }

  delegate :can?, :cannot?, to: :ability

  def register_totp(person)
    person.update!(two_factor_authentication: :totp,
      two_fa_secret: People::OneTimePassword.generate_secret)
  end

  def enforce_totp(person)
    allow(person).to receive(:two_factor_authentication_enforced?).and_return(true)
  end

  context "on own profile" do
    let(:person) { current_user }

    it "offers setup without disable if totp is not registered" do
      expect(html).to have_link "Zwei-Faktor-Authentifizierung einrichten",
        href: totp_reset_group_person_path(parent, person)
      expect(html).not_to have_link "Zwei-Faktor-Authentifizierung deaktivieren"
    end

    it "offers setup and disable if totp is registered" do
      register_totp(person)

      expect(html).to have_link "Zwei-Faktor-Authentifizierung einrichten",
        href: totp_reset_group_person_path(parent, person)
      expect(html).to have_link "Zwei-Faktor-Authentifizierung deaktivieren",
        href: totp_disable_group_person_path(parent, person)
    end

    it "offers setup only if totp is registered and enforced" do
      register_totp(person)
      enforce_totp(person)

      expect(html).to have_link "Zwei-Faktor-Authentifizierung einrichten"
      expect(html).not_to have_link "Zwei-Faktor-Authentifizierung deaktivieren"
    end
  end

  context "on other profile" do
    let(:person) { people(:bottom_member) }

    it "offers nothing about totp if it is not registered" do
      expect(html).not_to have_link "Zwei-Faktor-Authentifizierung einrichten"
      expect(html).not_to have_link "Zwei-Faktor-Authentifizierung deaktivieren"
    end

    it "offers only disable if totp is registered" do
      register_totp(person)

      expect(html).not_to have_link "Zwei-Faktor-Authentifizierung einrichten"
      expect(html).to have_link "Zwei-Faktor-Authentifizierung deaktivieren",
        href: totp_disable_group_person_path(parent, person)
      expect(html).to have_css("a.dropdown-item", text: "Zwei-Faktor", count: 1)
    end

    it "offers disable if totp is registered and enforced" do
      register_totp(person)
      enforce_totp(person)

      expect(html).to have_link "Zwei-Faktor-Authentifizierung deaktivieren"
    end
  end
end
