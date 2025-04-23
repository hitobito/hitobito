#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MessageRecipient do
  let(:recipient) { Fabricate(:message_recipient) }

  describe "normalization" do
    it "downcases email" do
      recipient.email = "TesTer@gMaiL.com"
      expect(recipient.email).to eq "tester@gmail.com"
    end
  end
end
