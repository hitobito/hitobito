# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Qualifier::StartAtCalculator do
  let(:person) { people(:bottom_member) }
  let(:slk) { event_kinds(:slk) }
  let(:gl) { qualification_kinds(:gl) }
  let(:role) { :participant }
  let(:today) { Time.zone.today }
  let!(:course) { create_course(training_days: 1, start_at: today - 1.month) }

  it "does not fail on empty prolongation kinds" do
    expect(described_class.new(person, course, [], role).start_at(gl)).to be_nil
  end

  it "does not fail on empty prolongation kinds without validity" do
    gl.update(validity: nil)
    expect(described_class.new(person, course, [gl], role).start_at(gl)).to be_nil
  end

  def create_course(start_at:, kind: slk, qualified: false, training_days: nil)
    Fabricate.build(:course, kind: kind, training_days: training_days).tap do |course|
      course.dates.build(start_at: start_at)
    end
  end
end
