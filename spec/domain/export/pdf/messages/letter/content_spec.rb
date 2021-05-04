# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Messages::Letter::Content do

  let(:options)   { {} }
  let(:top_leader) { people(:top_leader) }
  let(:letter)     { double(:letter, body: "Lieber {first_name} {last_name}") }
  let(:pdf)        { double(:pdf) }

  it "replaces defined placeholders" do
    expect(pdf).to receive(:markup).with("Lieber Top Leader")
    described_class.new(pdf, letter, options).render(top_leader)
  end

  it "ignores undefined placeholders" do
    letter = double(:letter, body: "Lieber {unsupported}")
    expect(pdf).to receive(:markup).with("Lieber {unsupported}")
    described_class.new(pdf, letter, options).render(top_leader)
  end

  it "does not fail on nil values" do
    expect(pdf).to receive(:markup).with("Lieber  ")
    described_class.new(pdf, letter, options).render(Person.new)
  end

  context "letter with multiple sections" do
    let(:letter) { messages(:letter) }

    it "creates two sections" do
      body = letter.body

    end

  end
end
