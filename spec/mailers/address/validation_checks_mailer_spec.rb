# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe Address::ValidationChecksMailer do
  let(:invalid_people) { [people(:top_leader), people(:bottom_member)] }
  let(:invalid_people_names) { invalid_people.map(&:full_name).join(", ") }
  let(:recipient_email) { "validation_checks@example.com" }
  let(:mail) { Address::ValidationChecksMailer.validation_checks(recipient_email, invalid_people_names) }

  context "validation checks mail" do
    it "shows full names of the invalid people" do
      expect(mail.subject).to eq("Address Validierungen")
      expect(mail.body).to include(invalid_people_names)
    end
  end
end
