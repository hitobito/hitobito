# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe HitobitoLogMailer do
  let(:mail) { described_class.error([HitobitoLogEntry.pluck(:id)], 1.day.ago..Time.zone.now) }

  before do
    Settings.hitobito_log.recipient_emails = ["it@hitobito.com", "test@hitobito.com"]
  end

  it "sends to every mail defined in hitobito log settings" do
    expect(mail.to).to match_array(["it@hitobito.com", "test@hitobito.com"])
  end
end
