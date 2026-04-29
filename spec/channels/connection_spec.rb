#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ApplicationCable::Connection, type: :channel do
  it "should successfully connect with logged in user" do
    person = people(:top_leader)
    warden = double("Warden")
    allow(warden).to receive(:user).with(:person).and_return(person)

    connect env: {"warden" => warden}
    expect(connection.current_person).to eql(person)
  end

  it "should reject connection without logged in user" do
    warden = double("Warden")
    allow(warden).to receive(:user).with(:person).and_return(nil)

    expect { connect env: {"warden" => warden} }.to have_rejected_connection
  end
end
