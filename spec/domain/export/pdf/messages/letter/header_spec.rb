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

  def assign_image(group)
    GroupSetting.create!(target: group, var: :messages_letter, picture: image).id
  end

  describe "image source" do
    def expects_image(id)
      path = %r{/picture/#{id}/logo\.png}
      image_options = options.merge(fit: [200, 40], position: :right)
      expect_any_instance_of(Prawn::Document).to receive(:image).with(path, image_options)
    end
    it "has no image" do
      expect_any_instance_of(Prawn::Document).not_to receive(:image)
      subject.render(top_leader)
    end

    it "has image from group" do
      id = assign_image(top_group)
      expects_image(id)
      subject.render(top_leader)
    end

    it "has image from layer" do
      id = assign_image(top_group.layer_group)
      expects_image(id)
      subject.render(top_leader)
    end

    it "has image from group if layer and group have an image " do
      _layer_id = assign_image(top_group.layer_group)
      group_id = assign_image(top_group)
      expects_image(group_id)
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
        [36, 747, "TopGroup"],
        [36, 734, "Belpstrasse 37"],
        [36, 720, "Bern"],
        [36, 669, "Top Leader"],
        [36, 642, "Supertown"]
      ]
    end

    it "same position when logo is present" do
      assign_image(top_group)
      subject.render(top_leader)

      expect(text_with_position).to eq [
        [36, 747, "TopGroup"],
        [36, 734, "Belpstrasse 37"],
        [36, 720, "Bern"],
        [36, 669, "Top Leader"],
        [36, 642, "Supertown"]
      ]
    end

    context "stamping" do
      let(:stamps) { pdf.instance_variable_get('@stamp_dictionary_registry') }
      let(:options) { { stamped: true } }

      it "includes only receiver address" do
        subject.render(top_leader)
        pdf.start_new_page
        subject.render(top_leader)
        expect(stamps.keys).to eq [:render_header]
        expect(text_with_position).to eq [
          [36, 669, "Top Leader"],
          [36, 642, "Supertown"],
          [36, 669, "Top Leader"],
          [36, 642, "Supertown"]
        ]
      end

      it "same position when image is present" do
        assign_image(top_group)
        subject.render(top_leader)
        pdf.start_new_page
        subject.render(top_leader)
        expect(stamps.keys).to eq [:render_header]
        expect(text_with_position).to eq [
          [36, 669, "Top Leader"],
          [36, 642, "Supertown"],
          [36, 669, "Top Leader"],
          [36, 642, "Supertown"]
        ]
      end
    end
  end

  describe "recipient address" do
    it "is present" do
      subject.render(top_leader)

      expect(text_with_position).to eq [
        [36, 669, "Top Leader"],
        [36, 642, "Supertown"]
      ]
    end

    it "same position when image is present" do
      assign_image(top_group)
      subject.render(top_leader)

      expect(text_with_position).to eq [
        [36, 669, "Top Leader"],
        [36, 642, "Supertown"]
      ]
    end

    it "does not render town if not set" do
      top_leader.town = nil
      subject.render(top_leader)

      expect(text_with_position).to eq [
        [36, 669, "Top Leader"],
      ]
    end

    it "does not render anything for blank values" do
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
