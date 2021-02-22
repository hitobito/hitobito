#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Cookies::AsyncSynchronization do
  let(:cookie_jar) { ActionDispatch::Request.new({}).cookie_jar }
  let(:value) { JSON.parse(cookie_jar[:async_synchronizations]) }
  let(:subject) { described_class.new(cookie_jar) }

  it "tracks single synchronization in cookie" do
    subject.set(mailing_list_id: 1)
    expect(value).to have(1).item
    expect(value.first["mailing_list_id"]).to eq 1
  end

  it "tracks multiple synchronizations in cookie" do
    subject.set(mailing_list_id: 1)
    subject.set(mailing_list_id: 2)
    expect(value).to have(2).items
  end

  it "removes synchronizations from values" do
    subject.set(mailing_list_id: 1)
    subject.set(mailing_list_id: 2)
    subject.remove(mailing_list_id: 1)

    expect(value).to have(1).items
    expect(value.first["mailing_list_id"]).to eq 2
  end

  it "removes cookie if no values are left" do
    subject.set(mailing_list_id: 1)
    subject.remove(mailing_list_id: 1)
    expect(cookie_jar).not_to have_key(:async_synchronizations)
  end
end
