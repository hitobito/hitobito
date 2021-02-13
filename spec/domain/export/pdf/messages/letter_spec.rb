# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Messages::Letter do
  let(:letter) { messages(:letter) }
  let(:recipients) { [people(:bottom_member)] }
  let(:options) { {} }

  subject { described_class.new(letter, recipients, options) }

  it "renders logo from settings" do
    expect_any_instance_of(Prawn::Document).to receive(:image).with(
      Settings.messages.pdf.logo.to_s,
      fit: [200, 40]
    )
    subject.render
  end

  it "renders context via markup processor" do
    expect(Prawn::Markup::Processor).to receive_message_chain(:new, :parse)
    subject.render
  end

  it "sanitizes filename" do
    letter.subject = "Liebe Mitglieder"
    expect(subject.filename).to eq "liebe_mitglieder.pdf"
  end

  context "preview" do
    let(:options) { {preview: true} }

    it "renders extra background image" do
      expect(Prawn::Document).to receive(:new).with(
        hash_including(background: Settings.messages.pdf.preview)
      ).and_call_original
      subject.render
    end

    it "includes preview in filename" do
      expect(subject.filename).to eq "information-preview.pdf"
    end
  end

  context "text" do
    subject do
      pdf = described_class.new(letter, recipients).render
      PDF::Inspector::Text.analyze(pdf)
    end

    it "renders text at positions" do
      text_with_position = subject.positions.each_with_index.collect { |p, i|
        p.collect(&:round) + [subject.show_text[i]]
      }
      expect(text_with_position).to match_array [
        [57, 729, "hitobito AG"],
        [57, 718, "Belpstrasse 37"],
        [57, 708, "3007 Bern"],
        [57, 669, "Bottom Member"],
        [57, 658, "Greatstreet 345"],
        [57, 648, "3456 Greattown"],
        [57, 638, "CH"],
        [57, 579, "Hallo Bottom"],
        [57, 558, "Wir laden "],
        [97, 558, "dich"],
        [116, 558, " ein! "],
        [57, 537, "Bis bald"],
      ]
    end
  end
end
