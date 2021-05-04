# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Messages::Letter::Header do
  let(:options)    { {} }
  let(:top_group)  { groups(:top_group) }
  let(:top_leader) { people(:top_leader) }
  let(:letter)     { Message::Letter.new(body: "simple text", group: top_group, heading: true) }
  let(:pdf)        { Prawn::Document.new }
  let(:analyzer) { PDF::Inspector::Text.analyze(pdf.render) }
  let(:image)    { fixture_file_upload('images/logo.png') }

  subject { described_class.new(pdf, letter, options) }

  describe "image source" do
    it "has no image" do
      expect_any_instance_of(Prawn::Document).not_to receive(:image)
      subject.render(top_leader)
    end

    it "has image from group" do
      id = GroupSetting.create!(target: top_group, var: :messages_letter, picture: image).id
      expect_any_instance_of(Prawn::Document).to receive(:image).with(%r{/picture/#{id}/logo\.png}, options.merge(fit: [200, 40]))
      subject.render(top_leader)
    end

    it "has image from layer" do
      id = GroupSetting.create!(target: top_group.layer_group, var: :messages_letter, picture: image).id
      expect_any_instance_of(Prawn::Document).to receive(:image).with(%r{/picture/#{id}/logo\.png}, options.merge(fit: [200, 40]))
      subject.render(top_leader)
    end

    it "has image from group if layer and group have an image " do
      GroupSetting.create!(target: top_group.layer_group, var: :messages_letter, picture: image)
      group_id = GroupSetting.create!(target: top_group, var: :messages_letter, picture: image).id
      expect_any_instance_of(Prawn::Document).to receive(:image).with(%r{/picture/#{group_id}/logo\.png}, options.merge(fit: [200, 40]))
      subject.render(top_leader)
    end
  end

  describe "sender address" do
    before do
      top_group.address = "Belpstrasse 37"
      top_group.town = "Bern"
    end

    it "is present" do
      subject.render(top_leader)
      expect(text_with_position).to eq [
        [36, 697, "TopGroup"],
        [36, 684, "Belpstrasse 37"],
        [36, 670, "Bern"],
        [36, 637, "Top Leader"],
        [36, 610, "Supertown"]
      ]
    end

    context "position relating to image" do
      it "same position when logo is present" do
        GroupSetting.create!(target: top_group, var: :messages_letter, picture: image)
        subject.render(top_leader)

        expect(text_with_position).to eq [
          [36, 697, "TopGroup"],
          [36, 684, "Belpstrasse 37"],
          [36, 670, "Bern"],
          [36, 637, "Top Leader"],
          [36, 610, "Supertown"]
        ]
      end

      it "moves up when when logo is placed on right side" do
        expect(Settings.messages.pdf).to receive(:logo_position).and_return(:right)
        GroupSetting.create!(target: top_group, var: :messages_letter, picture: image)
        subject.render(top_leader)

        expect(text_with_position).to eq [
          [36, 747, "TopGroup"],
          [36, 734, "Belpstrasse 37"],
          [36, 720, "Bern"],
          [36, 687, "Top Leader"],
          [36, 660, "Supertown"]
        ]
      end
    end

    context "stamping" do
      let(:stamps) { pdf.instance_variable_get('@stamp_dictionary_registry') }
      let(:options) { { stamped: true } }

      it "has stamp for header" do
        subject.render(top_leader)
        pdf.start_new_page
        subject.render(top_leader)
        expect(stamps.keys).to eq [:render_header]
        expect(text_with_position).to eq [
          [36, 637, "Top Leader"],
          [36, 610, "Supertown"],
          [36, 637, "Top Leader"],
          [36, 610, "Supertown"]
        ]
      end

      context "position relating to image" do
        it "same position when logo is present" do
          GroupSetting.create!(target: top_group, var: :messages_letter, picture: image)
          subject.render(top_leader)
          pdf.start_new_page
          subject.render(top_leader)

          expect(text_with_position).to eq [
            [36, 637, "Top Leader"],
            [36, 610, "Supertown"],
            [36, 637, "Top Leader"],
            [36, 610, "Supertown"],
          ]
        end

        it "moves up when when logo is placed on right side" do
          expect(Settings.messages.pdf).to receive(:logo_position).and_return(:right)
          GroupSetting.create!(target: top_group, var: :messages_letter, picture: image)
          subject.render(top_leader)
          pdf.start_new_page
          subject.render(top_leader)

          expect(text_with_position).to eq [
            [36, 687, "Top Leader"],
            [36, 660, "Supertown"],
            [36, 687, "Top Leader"],
            [36, 660, "Supertown"],
          ]
        end
      end
    end
  end

  describe "recipient address" do
    it "is present" do
      subject.render(top_leader)

      expect(text_with_position).to eq [
        [36, 637, "Top Leader"],
        [36, 610, "Supertown"]
      ]
    end

    context "position relating to image" do
      it "same position when logo is present" do
        GroupSetting.create!(target: top_group, var: :messages_letter, picture: image)
        subject.render(top_leader)

        expect(text_with_position).to eq [
          [36, 637, "Top Leader"],
          [36, 610, "Supertown"]
        ]
      end

      it "moves up when when logo is placed on right side" do
        expect(Settings.messages.pdf).to receive(:logo_position).and_return(:right)
        GroupSetting.create!(target: top_group, var: :messages_letter, picture: image)
        subject.render(top_leader)

        expect(text_with_position).to eq [
          [36, 687, "Top Leader"],
          [36, 660, "Supertown"]
        ]
      end
    end

    it "does not render town if not set" do
      top_leader.town = nil
      subject.render(top_leader)

      expect(text_with_position).to eq [
        [36, 637, "Top Leader"],
      ]
    end

    it "does not anything if name is not set" do
      top_leader.first_name = nil
      top_leader.last_name = nil
      top_leader.town = nil
      subject.render(top_leader)

      expect(text_with_position).to be_empty
    end
  end

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end
end
