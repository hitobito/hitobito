#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::DeviseOverrides do
  let(:person) { people(:top_leader) }

  context "#reset_password" do
    it "does reset password when no validation error" do
      person.reset_password("newpassword12345", "newpassword12345")
      expect(person.errors).to be_empty
    end

    it "adds password validation error when new password is too short" do
      person.reset_password("newpw", "newpw")
      expect(person.errors.full_messages).to eq ["Passwort ist zu kurz (weniger als 12 Zeichen)"]
    end

    it "adds password confirmation error when new password is not the same as confirmation" do
      person.reset_password("meinpasswort", "nichtmeinpasswort")
      expect(person.errors.full_messages).to eq ["Passwort Bestätigung stimmt nicht mit Passwort überein"]
    end

    it "removes every other validation erros besides password and password confirmation" do
      person.update_columns(first_name: nil, last_name: nil)
      person.reset_password("meinpasswort", "nichtmeinpasswort")
      expect(person.errors.full_messages).not_to include("Bitte geben Sie einen Namen ein")
    end

    it "saves new password even when other person validations are invalid" do
      person.update_columns(first_name: nil, last_name: nil)
      person.reset_password("newpassword12345", "newpassword12345")
      expect(person.errors).to be_empty
    end
  end
end
