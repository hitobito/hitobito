# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
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

  context 'heading' do

    let(:letter_setting) do
      GroupSetting.new(var: :messages_letter, picture: fixture_file_upload('images/logo.png'))
    end

    def expect_renders_logo_from_layer_settings(group = layer, options = {})
      letter.update!(heading: true)
      letter_setting.target = group
      letter_setting.save!

      expect_any_instance_of(Prawn::Document).to receive(:image).with(
        /\/picture\/#{letter_setting.id}\/logo\.png/,
        options.merge(fit: [200, 40])
      )
    end

    it 'renders no logo' do
      expect_any_instance_of(Prawn::Document).to receive(:image).never
      subject.render
    end

    it 'renders logo from layer setting' do
      expect_renders_logo_from_layer_settings

      subject.render
    end

    it 'renders logo from layer setting where setting is set on group' do
      expect_renders_logo_from_layer_settings(group)

      subject.render
    end

    it 'renders logo from layer setting where setting on right side' do
      expect(Settings.messages.pdf).to receive(:logo).and_return(:right)
      expect_renders_logo_from_layer_settings(group, position: :right)

      subject.render
    end

    it 'prefers group over layer logo' do
      letter.update!(heading: true)
      group_letter_setting = GroupSetting.create!(var: :messages_letter,
                                                  target: group,
                                                  picture: fixture_file_upload('images/logo.png'))

      GroupSetting.create!(var: :messages_letter,
                           target: layer,
                           picture: fixture_file_upload('images/logo.png'))

      expect_any_instance_of(Prawn::Document).to receive(:image).with(
        /\/picture\/#{group_letter_setting.id}\/logo\.png/,
        fit: [200, 40]
      )
      subject.render
    end
  end

  it 'renders context via markup processor' do
    expect(Prawn::Markup::Processor).to receive_message_chain(:new, :parse)
    subject.render
  end

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
    subject do
      pdf = described_class.new(letter, recipients).render
      PDF::Inspector::Text.analyze(pdf)
    end

    it 'renders text at positions without sender address' do
      expect(text_with_position).to match_array [
        [57, 669, 'Bottom Member'],
        [57, 658, 'Greatstreet 345'],
        [57, 648, '3456 Greattown'],
        [57, 579, 'Hallo Bottom'],
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
        [57, 579, 'Hallo Bottom'],
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
        [57, 579, 'Hallo Bottom'],
        [57, 558, 'Wir laden '],
        [97, 558, 'dich'],
        [116, 558, ' ein! '],
        [57, 537, 'Bis bald']
      ]
    end
  end

  private

  def text_with_position
    subject.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [subject.show_text[i]]
    end
  end

end
