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

  context "devise recoverable" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:person) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: group).person.reload }

    it "can reset password" do
      expect { person.send_reset_password_instructions }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  context "devise lockable" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:person) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: group).person.reload }

    it "does send unlock instructions via email" do
      expect { person.send_unlock_instructions }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it "does not send unlock instructions if email is blank" do
      person.update!(email: nil)
      expect { person.send_unlock_instructions }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  describe "email confirmation" do
    # Covers security issue, see https://github.com/heartcombo/devise/issues/5783
    # Can be removed as soon as devise releases https://github.com/heartcombo/devise/pull/5784
    it "handles race condition security issue" do
      attacker_email = "attacker@example.com"
      victim_email = "victim@example.com"

      attacker = Fabricate(:person, password: "passwordpassword", password_confirmation: "passwordpassword")
      # update the email address of the attacker, but do not confirm it yet
      attacker.update(email: attacker_email)

      # a concurrent request also updates the email address to the victim, while this request's model is in memory
      Person.where(id: attacker.id).update_all(
        unconfirmed_email: victim_email,
        confirmation_token: "different token"
      )

      # now we update to the same prior unconfirmed email address, and confirm
      attacker.update(email: attacker_email)
      attacker_token = attacker.confirmation_token
      Person.confirm_by_token(attacker_token)

      attacker.reload
      assert attacker.confirmed?
      assert_equal attacker_email, attacker.email
    end
  end

  context "devise confirmable" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:person) { Fabricate(Group::BottomGroup::Member.name.to_sym, group: group).person.reload }

    it "does send confirmation instructions via email" do
      person.update!(email: nil, unconfirmed_email: "new_mail@example.net")

      expect do
        person.send_confirmation_instructions
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it "does not send confirmation instructions if unconfirmed email is blank" do
      person.update!(email: "ye-olde-maileth@example.net", unconfirmed_email: nil)

      expect do
        person.send_confirmation_instructions
      end.not_to change { ActionMailer::Base.deliveries.size }
    end
  end
end
