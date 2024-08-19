# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wizards::InscribeInGroupWizard do
  let(:role_type) { Group::TopGroup::Member }
  let(:group) { groups(:top_group) }
  let(:person) { people(:bottom_member) }

  subject(:wizard) { described_class.new(group:, person:) }

  context "if self registration isn't enabled" do
    it "raises a runtime error" do
      expect { wizard }.to raise_error(RuntimeError)
    end
  end

  context "when self registration is enabled" do
    before { group.update!(self_registration_role_type: role_type) }

    it "creates role correctly" do
      expect(wizard.role).to be_a(role_type)
    end

    describe "#save!" do
      it "Creates a new role" do
        expect { wizard.save! }
          .to change { Role.count }.by(1)
      end

      context "when self_registration_notification email is set" do
        before { group.update!(self_registration_notification_email: "example@example.com") }

        it "Sends an eamil" do
          expect { wizard.save! }
            .to change { enqueued_mail_jobs_count }.by(1)
        end
      end
    end
  end
end
