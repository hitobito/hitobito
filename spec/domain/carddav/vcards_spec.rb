# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Carddav::Vcards do
  let(:person) { people(:top_leader) }

  subject(:vcard) { described_class.new.generate_for(person) }

  it "carries the contact data of the plain vcard export" do
    expect(vcard).to include "FN:Top Leader"
    expect(vcard).to include "EMAIL;TYPE=pref:top_leader@example.com"
  end

  it "identifies the person with a stable uid" do
    expect(vcard).to include "UID:hitobito-person-#{person.id}"
  end

  it "tells when the person last changed" do
    expect(vcard).to include "REV:#{person.updated_at.utc.strftime("%Y%m%dT%H%M%SZ")}"
  end

  it "separates the lines with CRLF, as required for carddav" do
    expect(vcard.lines.first).to eq "BEGIN:VCARD\r\n"
    expect(vcard).not_to match(/[^\r]\n/)
  end
end
