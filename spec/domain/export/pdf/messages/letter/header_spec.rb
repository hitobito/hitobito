# frozen_string_literal: true

#  Copyright (c) 2021-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Pdf::Messages::Letter::Header do
  include PdfHelpers

  let(:base_options) do
    {
      margin: Export::Pdf::Messages::Letter::MARGIN,
      page_size: 'A4',
      page_layout: :portrait,
      compress: true
    }
  end
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

  let(:shipping_info_with_position_left) do
    [
      [71, 672, 'P.P.'],
      [91, 672, ' '],
      [134, 685, 'Post CH AG'],
      [94, 672, 'CH-3030 Bern, Belpstrasse 37'],
    ]
  end
  let(:shipping_info_with_position_right) do
    [
      [424, 685, 'Post CH AG'],
      [361, 672, 'P.P.'],
      [381, 672, ' '],
      [384, 672, 'CH-3030 Bern, Belpstrasse 37']
    ]
  end

  subject { described_class.new(pdf, letter, options) }

  def expects_image(id)
    image_options = { position: :right }
    expect_any_instance_of(Prawn::Document)
      .to receive(:image).with(instance_of(Tempfile), image_options)
  end

  describe 'logo' do

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

    it 'has the correct position and size' do
      assign_image(top_group.layer_group)
      subject.render(recipient)

      expect(image_positions).to have(1).item
      expect(image_positions.first).to match(
        x: 294.41386,
        y: 741.02386,
        width: 230,
        height: 30,
        displayed_width: 52_900.0,
        displayed_height: 900.0
      )
    end

    context 'image scaling' do
      it 'does not scale if image smaller than logo box' do
        assign_image(top_group, 'images/logo.png') # 230x30px
        subject.render(recipient)

        expect(image_positions.first).to match(
          x: 294.41386,
          y: 741.02386,
          width: 230,
          height: 30,
          displayed_width: 52_900.0,
          displayed_height: 900.0
        )
      end

      it 'scales down image if image width exceeds logo box' do
        assign_image(top_group, 'images/logo_1000x40.png') # 1000x40px
        subject.render(recipient)

        expect(image_positions.first).to match(
          x: 74.41386,
          y: 753.02386,
          width: 1000,
          height: 40,
          displayed_width: 450_000.0,
          displayed_height: 720.0
        )
      end

      it 'scales down image if image height exceeds logo box' do
        assign_image(top_group, 'images/logo_200x100.png') # 200x100px
        subject.render(recipient)

        expect(image_positions.first).to match(
          x: 444.41386,
          y: 731.02386,
          width: 200,
          height: 100,
          displayed_width: 16_000.0,
          displayed_height: 4000.0
        )
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
      id = assign_image(top_group)
      expects_image(id)
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
          [71, 655, 'Top Leader'],
          [71, 627, 'Supertown']
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
          [71, 655, 'Top Leader'],
          [71, 627, 'Supertown']
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

    context 'rendered left' do
      before do
        top_group.letter_address_position = :left
        top_group.save!
      end

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

    context 'rendered right' do
      before do
        top_group.letter_address_position = :right
        top_group.save!
      end

      it 'is present' do
        subject.render(recipient)

        expect(text_with_position_without_shipping_info).to eq [
          [361, 652, 'Top Leader'],
          [361, 624, 'Supertown']
        ]
      end

      it 'same position when image is present' do
        assign_image(top_group)
        subject.render(recipient)

        expect(text_with_position_without_shipping_info).to eq [
          [361, 652, 'Top Leader'],
          [361, 624, 'Supertown']
        ]
      end

      it 'does not render town if not set' do
        recipient.address = 'Top Leader'
        subject.render(recipient)

        expect(text_with_position_without_shipping_info).to eq [
          [361, 652, 'Top Leader']
        ]
      end

      it 'does not render anything for blank values' do
        recipient.address = nil
        subject.render(recipient)

        expect(text_with_position_without_shipping_info).to be_empty
      end
    end
  end

  describe 'shipping_info' do
    context 'rendered left' do
      it 'is present' do
        subject.render(recipient)

        shipping_info_with_position_left.each do |shipping_info|
          expect(text_with_position).to include(shipping_info)
        end
      end
    end

    context 'rendered right' do
      before do
        top_group.letter_address_position = :right
        top_group.save!
      end

      it 'is present' do
        subject.render(recipient)

        shipping_info_with_position_right.each do |shipping_info|
          expect(text_with_position).to include(shipping_info)
        end
      end
    end
  end

  private

  def text_with_position_without_shipping_info
    text_with_position - (shipping_info_with_position_left + shipping_info_with_position_right)
  end

  def assign_image(group, image = 'images/logo.png')
    group.letter_logo.attach(fixture_file_upload(image))
    group.save!

    group.id
  end

end
