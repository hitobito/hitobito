# frozen_string_literal: true

#  Copyright (c) 2025-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe NilArrayCoder do
  subject { described_class } # only class-methods

  it "can dump nil" do
    expect(subject.dump(nil)).to eql "null"
  end

  it "can dump an empty Array" do
    expect(subject.dump([])).to eql "[]"
  end

  it "can dump a filled Array" do
    expect(subject.dump(%w[street zip_code town])).to eql '["street","zip_code","town"]'
  end

  it "loads nil as an empty Array" do
    expect(subject.load(nil)).to eql []
  end

  it "loads NULL from the DB as an empty Array" do
    expect(subject.load(nil)).to eql []
  end

  it "loads JSON-null as an empty Array" do
    expect(subject.load("null")).to eql []
  end

  it "can load an Array in YAML-Format" do
    yaml_string = <<~YAML
      ---
      - street
      - zip_code
      - town

    YAML

    expect(subject.load(yaml_string)).to eql %w[street zip_code town]
  end

  it "can load an Array in JSON-Format" do
    expect(subject.load('["street","zip_code","town"]')).to eql %w[street zip_code town]
  end
end
