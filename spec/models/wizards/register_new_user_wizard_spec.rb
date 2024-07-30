# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wizards::RegisterNewUserWizard do
  let(:params) { {} }
  let(:role_type) { Group::TopGroup::Member }
  let(:group) { groups(:top_group) }

  subject(:wizard) do
    described_class.new(group: group, **params).tap { |w| w.step_at(0) }
  end

  subject(:new_user_form) { wizard.new_user_form }

  describe "populating main_person" do
    it "does not fail on empty params" do
      expect { wizard }.not_to raise_error
    end

    it "does populate person attrs" do
      params[:new_user_form] = {first_name: "test"}
      expect(new_user_form).to be_kind_of(Wizards::Steps::NewUserForm)
      expect(new_user_form.first_name).to eq "test"
    end
  end

  describe "#requires_adult_consent" do
    it "reads self_registration_require_adult_consent from group" do
      expect(wizard).not_to be_requires_adult_consent
      group.self_registration_require_adult_consent = true
      expect(wizard).to be_requires_adult_consent
    end
  end

  context "with self_wizard_role_type on group" do
    before { group.update!(self_registration_role_type: role_type) }

    describe "validations" do
      it "is invalid if attributes are not present" do
        expect(wizard).not_to be_valid
        expect(new_user_form.errors).to have(2).item
        expect(new_user_form.errors[:first_name][0]).to eq "muss ausgefüllt werden"
        expect(new_user_form.errors[:last_name][0]).to eq "muss ausgefüllt werden"
      end

      it "is valid if required attributes are present" do
        params[:new_user_form] = {first_name: "test", last_name: "test"}
        expect(new_user_form).to be_valid
      end
    end

    describe "#save!" do
      let(:person) { Person.find_by(first_name: "test") }

      it "saves person and role" do
        params[:new_user_form] = {first_name: "test"}
        expect { wizard.save! }.to change { Person.count }.by(1)
          .and change { group.roles.where(type: role_type.sti_name).count }.by(1)
        expect(person.last_name).to be_blank
        expect(person.privacy_policy_accepted).to be_blank
      end

      it "updates all person fields" do
        params[:new_user_form] = {
          first_name: "test",
          last_name: "dummy",
          company: true,
          company_name: true,
          email: "test@example.com",
          privacy_policy_accepted: true
        }
        freeze_time
        wizard.save!
        expect(person.privacy_policy_accepted_at).to eq Time.zone.now
        expect(person.last_name).to eq "dummy"
        expect(person.email).to eq "test@example.com"
        expect(person).to be_company
      end

      it "raises if save! fails" do
        params[:new_user_form] = {email: "top.leader@example.com"}
        expect { wizard.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
