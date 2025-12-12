#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Message do
  it "#to_s shows truncated subject with type" do
    subject.subject = "This is a very long text"
    subject.type = Message::Letter.sti_name
    expect(subject.to_s).to eq "Brief: This is a very lo..."
  end

  it "can create message without sender" do
    mailing_lists(:leaders).messages.create!(subject: "test", type: "Message")
  end

  context "#destroy" do
    it "might be destroy when no dispatch exists" do
      expect(messages(:letter).destroy).to be_truthy
    end

    it "existing recipient prevents destruction" do
      expect(messages(:simple).destroy).to eq false
    end
  end
end
