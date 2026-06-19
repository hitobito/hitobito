#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AppStatus::Composed do
  let(:status_one) { double("AppStatus::One", details: {name: "Tom", food: "Pizza"}, code: :ok) }
  let(:status_two) { double("AppStatus::Two", details: {teapot: true}, code: :ok) }

  it "should merge details of statuses" do
    composed_status = AppStatus::Composed.new(status_one, status_two)

    expect(composed_status.details).to eql({name: "Tom", food: "Pizza", teapot: true})
  end

  it "should have code ok when all statuses have code ok" do
    composed_status = AppStatus::Composed.new(status_one, status_two)

    expect(composed_status.code).to eql(:ok)
  end

  it "should have code service unavailable when a status doesnt have code ok" do
    failing_status = double("AppStatus::Three", details: {out_of_food: true}, code: :some_other_code)
    composed_status = AppStatus::Composed.new(status_one, status_two, failing_status)

    expect(composed_status.code).to eql(:service_unavailable)
  end
end
