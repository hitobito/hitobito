# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Messages::Letter::Content do

  let(:options)    { {} }
  let(:top_leader) { people(:top_leader) }
  let(:letter)     { Message::Letter.new(body: "simple text") }
  let(:pdf)        { Prawn::Document.new }
  let(:analyzer)   { PDF::Inspector::Text.analyze(pdf.render) }

  subject { described_class.new(pdf, letter, options) }

  context "salutation" do
    it "renders body" do
      subject.render(top_leader)
      expect(text_with_position).to eq [[36, 747, "simple text"]]
    end

    it "prepends salutation if set" do
      letter.salutation = "default"
      subject.render(top_leader)
      expect(text_with_position).to eq [
        [36, 747, "Hallo Top"],
        [36, 710, "simple text"],
      ]
    end

    it "prepends personal salutation applicable" do
      letter.salutation = :lieber_vorname
      top_leader.gender = "m"
      subject.render(top_leader)
      expect(text_with_position).to eq [
        [36, 747, "Lieber Top"],
        [36, 710, "simple text"],
      ]
    end
  end

  context "stamping" do
    before do
      top_leader.gender = "m"
      letter.salutation = "default"
    end

    let(:stamps) { pdf.instance_variable_get('@stamp_dictionary_registry') }

    it "has positions for salutation and text" do
      subject.render(top_leader)
      pdf.start_new_page
      subject.render(top_leader)
      expect(text_with_position).to eq [
        [36, 747, "Hallo Top"],
        [36, 710, "simple text"],
        [36, 747, "Hallo Top"],
        [36, 710, "simple text"]
      ]
      expect(stamps).to be_nil
    end

    it "has stamps for content" do
      options[:stamped] = true
      subject.render(top_leader)
      pdf.start_new_page
      subject.render(top_leader)
      expect(text_with_position).to eq [
        [36, 747, "Hallo Top"],
        [36, 747, "Hallo Top"],
      ]
      expect(stamps.keys).to eq [:render_content]
    end

    it "has stamps for different salutations and content" do
      options[:stamped] = true
      subject.render(top_leader)
      pdf.start_new_page
      subject.render(Person.new)
      expect(stamps.keys).to eq [:render_content, :salutation_generic]
      # TODO: Unsure why in this case font in analyzer is empty
      # expect(text_with_position).to be_empty #
    end
  end

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end
end
