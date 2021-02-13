# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::SendRegisterLoginJob do

  let(:group) { event.groups.first }
  let(:event) { events(:top_event) }

  let(:person) { Fabricate(:person) }

  subject { Event::SendRegisterLoginJob.new(person, group, event) }


  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
  end

  it "creates reset password token" do
    subject.perform
    expect(person.reload.reset_password_token).to be_present
  end

  it "sends email" do
    subject.perform

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(last_email.subject).to eq("Anmeldelink für Anlass")
  end

end
