# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Messages::LetterDispatch do
  let(:message)    { messages(:letter) }
  let(:top_leader) { people(:top_leader) }

  subject { described_class.new(message, Person.where(id: top_leader.id)) }

  it "updates success count" do
    subject.run
    expect(message.reload.success_count).to eq 1
  end

  it "creates recipient" do
    subject.run
    recipient = message.message_recipients.first
    expect(recipient.message).to eq message
    expect(recipient.person).to eq top_leader
    expect(recipient.address).to eq "Top Leader\n\nSupertown\n"
  end
end
