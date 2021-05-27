# frozen_string_literal: true

#  Copyright (c) 2020-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Messages::Letter do

  let(:letter) do
    Message::Letter.create!(mailing_list: list,
                            body: messages(:letter).body,
                            subject: "Information")
  end
  let(:recipients) { [people(:bottom_member)] }
  let(:options) { {} }
  let(:layer) { groups(:top_layer) }
  let(:group) { groups(:top_group) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  subject { described_class.new(letter, recipients, options) }

  it "sanitizes filename" do
    letter.subject = "Liebe Mitglieder"
    expect(subject.filename).to eq "liebe_mitglieder.pdf"
  end

  it "prepends arguments passed" do
    letter.subject = "Liebe Mitglieder"
    expect(subject.filename(:preview)).to eq "preview-liebe_mitglieder.pdf"
  end

  context "text" do
    let(:analyzer) { PDF::Inspector::Text.analyze(subject.render) }

    context "single recipient" do
      it "renders text at positions without sender address" do
        expect(text_with_position).to match_array [
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
      end

      it "renders text at positions with group sender address" do
        letter.update!(heading: true)
        group.update!(town: "Wanaka", address: "Lakeview 42")

        expect(text_with_position).to match_array [
          [71, 765, "TopGroup"],
          [71, 754, "Lakeview 42"],
          [71, 744, "Wanaka"],
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
      end

      it "renders text at positions with layer sender address" do
        letter.update!(heading: true)
        layer.update!(town: "Wanaka", address: "Lakeview 42", zip_code: "4242")

        expect(text_with_position).to match_array [
          [71, 765, "Top"],
          [71, 754, "Lakeview 42"],
          [71, 744, "4242 Wanaka"],
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
      end

      it "renders example letter" do
        options[:debug] = true
        image = fixture_file_upload("images/logo.png")
        GroupSetting.create!(target: groups(:top_group), var: :messages_letter, picture: image).id
        letter.update!(heading: true, group: groups(:top_group))
        layer.update!(town: "Wanaka", address: "Lakeview 42", zip_code: "4242", town: "Bern")
        IO.binwrite("/tmp/file.pdf", subject.render)
      end
    end

    context "stamping" do
      let(:recipients) { [people(:bottom_member), people(:top_leader)] }
      let(:stamps) { subject.pdf.instance_variable_get("@stamp_dictionary_registry") }

      it "renders addresses and content" do
        expect(text_with_position).to eq [
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"],
          [71, 687, "Top Leader"],
          [71, 666, "Supertown"],
          [71, 531, "Information"],
          [71, 502, "Hallo"],
          [71, 481, "Wir laden "],
          [111, 481, "dich"],
          [130, 481, " ein! "],
          [71, 460, "Bis bald"]
        ]
        expect(stamps).to be_nil
      end

      it "renders only addresses has stamps" do
        options[:stamped] = true
        expect(text_with_position).to eq [
          [71, 687, "Bottom Member"],
          [71, 676, "Greatstreet 345"],
          [71, 666, "3456 Greattown"],
          [71, 687, "Top Leader"],
          [71, 666, "Supertown"],
        ]
        expect(stamps.keys).to eq [:render_header, :render_subject, :render_content]
      end

      it "falls back to normal rending if stamping fails because content is to big" do
        letter.body = Faker::Lorem.paragraphs(number: 100)
        options[:stamped] = true
        expect(text_with_position).to be_present
        expect(stamps).to be_nil
      end
    end
  end

  private

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end
end
