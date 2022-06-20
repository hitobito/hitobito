# frozen_string_literal: true

#  Copyright (c) 2021-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Pdf::Messages::Letter::Header do
  let(:base_options) { {
    margin: Export::Pdf::Messages::Letter::MARGIN,
    page_size: 'A4',
    page_layout: :portrait,
    compress: true
  } }
  let(:options) { base_options }
  let(:top_group)  { groups(:top_group) }
  let(:top_leader) { people(:top_leader) }
  let(:recipient) do
    MessageRecipient
      .new(message: letter, person: top_leader, address: "Top Leader\n\nSupertown")
  end
  let(:letter) do
    Message::Letter.new(body: 'simple text', group: top_group,
                        shipping_method: 'normal', pp_post: 'CH-3030 Bern, Belpstrasse 37')
  end
  let(:pdf)      { Prawn::Document.new(options) }
  let(:analyzer) { PDF::Inspector::Text.analyze(pdf.render) }
  let(:image)    { Rails.root.join('spec/fixtures/files/images/logo.png') }
  let(:shipping_info_with_position) do
    [
      [71, 672, 'P.P.'],
      [91, 672, ' '],
      [180, 685, 'Post CH AG'],
      [94, 672, 'CH-3030 Bern, Belpstrasse 37']
    ]
  end

  subject { described_class.new(pdf, letter, options) }

  describe 'logo' do

    def expects_image(id)
      image_options = { position: :right }
      expect_any_instance_of(Prawn::Document)
        .to receive(:image).with(instance_of(StringIO), image_options)
    end

    it 'has no logo' do
      expect_any_instance_of(Prawn::Document).not_to receive(:image)
      subject.render(recipient)
    end

    it 'has logo from group' do
      id = assign_image(top_group)
      expects_image(id)
      subject.render(recipient)
    end

    it 'has logo from layer' do
      id = assign_image(top_group.layer_group)
      expects_image(id)
      subject.render(recipient)
    end

    it 'has logo from group if layer and group have a logo' do
      _layer_id = assign_image(top_group.layer_group)
      group_id = assign_image(top_group)
      expects_image(group_id)
      subject.render(recipient)
    end

    context 'image scaling' do

      let(:image) { Rails.root.join("spec/fixtures/files/#{@image}") }
      # let(:image_group_id) { assign_image(top_group) }
      # let(:image_path) { %r{/picture/#{image_group_id}/logo.*\.png} }

      xit 'does not scale if image smaller than logo box' do
        @image = 'images/logo.png' # 230x30px

        image_options = options.merge(position: :right)
        expect_any_instance_of(Prawn::Document)
          .to receive(:image).with(instance_of(StringIO), image_options)

        subject.render(recipient)
      end

      xit 'scales down image if image width exceeds logo box' do
        @image = 'images/logo_1000x40.png'

        image_options = options.merge(fit: [450, 40], position: :right)
        expect_any_instance_of(Prawn::Document)
          .to receive(:image).with(instance_of(StringIO), image_options)

        subject.render(recipient)
      end

      xit 'scales down image if image height exceeds logo box' do
        @image = 'images/logo_200x100.png'

        image_options = options.merge(fit: [450, 40], position: :right)
        expect_any_instance_of(Prawn::Document)
          .to receive(:image).with(instance_of(StringIO), image_options)

        subject.render(recipient)
      end
    end
  end

  describe 'sender address' do
    before do
      top_group.address = 'Belpstrasse 37'
      top_group.town = 'Bern'
    end

    it 'is present' do
      subject.render(recipient)
      expect(text_with_position_without_shipping_info).to eq [
        [71, 652, 'Top Leader'],
        [71, 624, 'Supertown']
      ]
    end

    it 'same position when logo is present' do
      assign_image(top_group)
      subject.render(recipient)

      expect(text_with_position_without_shipping_info).to eq [
        [71, 652, 'Top Leader'],
        [71, 624, 'Supertown']
      ]
    end

    context 'stamping' do
      let(:stamps) { pdf.instance_variable_get('@stamp_dictionary_registry') }
      let(:options) { base_options.merge({ stamped: true }) }

      it 'includes only receiver address' do
        subject.render(recipient)
        pdf.start_new_page
        subject.render(recipient)
        expect(stamps.keys).to eq [:render_logo_right, :render_shipping_info]
        expect(text_with_position_without_shipping_info).to eq [
          [71, 652, 'Top Leader'],
          [71, 624, 'Supertown'],
          [71, 652, 'Top Leader'],
          [71, 624, 'Supertown']
        ]
      end

      it 'same position when image is present' do
        assign_image(top_group)
        subject.render(recipient)
        pdf.start_new_page
        subject.render(recipient)
        expect(stamps.keys).to eq [:render_logo_right, :render_shipping_info]
        expect(text_with_position_without_shipping_info).to eq [
          [71, 652, 'Top Leader'],
          [71, 624, 'Supertown'],
          [71, 652, 'Top Leader'],
          [71, 624, 'Supertown']
        ]
      end

      it 'renders date location text above subject' do
        letter.update!(subject: 'Then answer is 42!', date_location_text: 'Magrathea, 21.12.2042')
        subject.render(recipient)
        pdf.start_new_page
        subject.render(recipient)
        expect(stamps.keys).to include(:render_subject)
        expect(stamps.keys).to include(:render_date_location_text)
      end
    end
  end

  describe 'recipient address' do
    it 'is present' do
      subject.render(recipient)

      expect(text_with_position_without_shipping_info).to eq [
        [71, 652, 'Top Leader'],
        [71, 624, 'Supertown']
      ]
    end

    it 'same position when image is present' do
      assign_image(top_group)
      subject.render(recipient)

      expect(text_with_position_without_shipping_info).to eq [
        [71, 652, 'Top Leader'],
        [71, 624, 'Supertown']
      ]
    end

    it 'does not render town if not set' do
      recipient.address = 'Top Leader'
      subject.render(recipient)

      expect(text_with_position_without_shipping_info).to eq [
        [71, 652, 'Top Leader']
      ]
    end

    it 'does not render anything for blank values' do
      recipient.address = nil
      subject.render(recipient)

      expect(text_with_position_without_shipping_info).to be_empty
    end
  end

  describe 'shipping_info' do
    it 'is present' do
      subject.render(recipient)

      shipping_info_with_position.each do |shipping_info|
        expect(text_with_position).to include(shipping_info)
      end
    end
  end

  private

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end

  def text_with_position_without_shipping_info
    text_with_position - shipping_info_with_position
  end

  def assign_image(group)
    gs = GroupSetting.create!(target: group, var: :messages_letter)
    gs.picture.attach(io: StringIO.new(image.read), filename: image.basename.to_s)

    gs.id
  end

end
