# frozen_string_literal: true

#  Copyright (c) 2020-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Pdf::Messages::Letter do

  let(:letter) do
    Message::Letter.create!(mailing_list: list,
                            body: messages(:letter).body,
                            subject: 'Information')
  end
  let(:recipients) { [people(:bottom_member)] }
  let(:options) { {} }
  let(:layer) { groups(:top_layer) }
  let(:group) { groups(:top_group) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  subject { described_class.new(letter, recipients, options) }

  it 'sanitizes filename' do
    letter.subject = 'Liebe Mitglieder'
    expect(subject.filename).to eq 'liebe_mitglieder.pdf'
  end

  context 'preview' do
    let(:options) { { preview: true } }

    it 'renders extra background image' do
      expect(Prawn::Document).to receive(:new).with(
        hash_including(background: Settings.messages.pdf.preview)
      ).and_call_original
      subject.render
    end

    it 'includes preview in filename' do
      expect(subject.filename).to eq 'information-preview.pdf'
    end
  end

  context 'text' do
    let(:analyzer) { PDF::Inspector::Text.analyze(subject.render) }

    context "single recipient" do

      it 'renders text at positions without sender address' do
        expect(text_with_position).to match_array [
          [57, 669, 'Bottom Member'],
          [57, 658, 'Greatstreet 345'],
          [57, 648, '3456 Greattown'],
          [57, 579, 'Hallo'],
          [57, 558, 'Wir laden '],
          [97, 558, 'dich'],
          [116, 558, ' ein! '],
          [57, 537, 'Bis bald']
        ]
      end

      it 'renders text at positions with group sender address' do
        letter.update!(heading: true)
        group.update!(town: 'Wanaka', address: 'Lakeview 42')

        expect(text_with_position).to match_array [
          [57, 729, 'TopGroup'],
          [57, 718, 'Lakeview 42'],
          [57, 708, 'Wanaka'],
          [57, 669, 'Bottom Member'],
          [57, 658, 'Greatstreet 345'],
          [57, 648, '3456 Greattown'],
          [57, 579, 'Hallo'],
          [57, 558, 'Wir laden '],
          [97, 558, 'dich'],
          [116, 558, ' ein! '],
          [57, 537, 'Bis bald']
        ]
      end

      it 'renders text at positions with layer sender address' do
        letter.update!(heading: true)
        layer.update!(town: 'Wanaka', address: 'Lakeview 42', zip_code: '4242')

        expect(text_with_position).to match_array [
          [57, 729, 'Top'],
          [57, 718, 'Lakeview 42'],
          [57, 708, '4242 Wanaka'],
          [57, 669, 'Bottom Member'],
          [57, 658, 'Greatstreet 345'],
          [57, 648, '3456 Greattown'],
          [57, 579, 'Hallo'],
          [57, 558, 'Wir laden '],
          [97, 558, 'dich'],
          [116, 558, ' ein! '],
          [57, 537, 'Bis bald']
        ]
      end
    end

    context "stamping" do
      let(:recipients) { [people(:bottom_member), people(:top_leader)] }
      let(:stamps) { subject.pdf.instance_variable_get('@stamp_dictionary_registry') }

      it "renders addresses and content" do
        expect(text_with_position).to eq [
        [57, 669, "Bottom Member"],
         [57, 658, "Greatstreet 345"],
         [57, 648, "3456 Greattown"],
         [57, 579, "Hallo"],
         [57, 558, "Wir laden "],
         [97, 558, "dich"],
         [116, 558, " ein! "],
         [57, 537, "Bis bald"],
         [57, 669, "Top Leader"],
         [57, 648, "Supertown"],
         [57, 579, "Hallo"],
         [57, 558, "Wir laden "],
         [97, 558, "dich"],
         [116, 558, " ein! "],
         [57, 537, "Bis bald"]
        ]
        expect(stamps).to be_nil
      end

      it "renders only addresses has stamps" do
        options[:stamped] = true
        expect(text_with_position).to eq [
          [57, 669, "Bottom Member"],
          [57, 658, "Greatstreet 345"],
          [57, 648, "3456 Greattown"],
          [57, 669, "Top Leader"],
          [57, 648, "Supertown"]
        ]
        expect(stamps.keys).to eq [:render_header, :render_content]
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
