# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


class Invoice::Qrcode

  SWISS_CROSS_EDGE_SIDE_PX = 166
  SWISS_CROSS_EDGE_SIDE_MM = 7

  # The edge length of the qrcode inclusive its white border.
  QR_CODE_EDGE_SIDE_MM = 42 + 13
  QR_CODE_EDGE_SIDE_PX = SWISS_CROSS_EDGE_SIDE_PX / SWISS_CROSS_EDGE_SIDE_MM * QR_CODE_EDGE_SIDE_MM
  QR_CROSS_X = (QR_CODE_EDGE_SIDE_PX / 2) - SWISS_CROSS_EDGE_SIDE_PX / 2
  QR_CROSS_Y = (QR_CODE_EDGE_SIDE_PX / 2) - SWISS_CROSS_EDGE_SIDE_PX / 2


  def initialize(invoice)
    @invoice = invoice
  end

  # see https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-de.pdf 4.3.3
  def payload
    striped_values(
      metadata,
      creditor.reverse_merge(iban: @invoice.iban.gsub(/\s+/, '')),
      creditor_final,
      payment,
      debitor,
      payment_reference,
      additional_infos,
      alternative_payment
    ).join("\r\n")
  end

  def metadata
    { type: 'SPC', version: '0200', coding: '1' }
  end

  def creditor
    extract_contact(@invoice.payee)
  end

  def creditor_final
    extract_contact(@invoice.payee).keys.product([nil]).to_h # optional, mock with nil values
  end

  def payment
    { amount: format('%<total>.2f', total: @invoice.total), currency: @invoice.currency }
  end

  def debitor
    extract_contact(@invoice.recipient_address)
  end

  def payment_reference
    type = @invoice.reference.starts_with?('RF') ? 'SCOR' : 'QRR'
    { type: type, reference: @invoice.reference }
  end

  def additional_infos
    {
      purpose: @invoice.payment_information.to_s.gsub("\n", " ").truncate(120),
      trailer: 'EPD',
      infos: nil
    }
  end

  def alternative_payment
    { type: nil }
  end

  def scissor(kind)
    image("schere_#{kind}.png")
  end

  def generate
    Tempfile.create([@invoice.sequence_number, '.png'], binmode: true) do |file|
      qrcode = generate_png
      cross  = ChunkyPNG::Image.from_file(image('CH-Kreuz_7mm_small.png'))
      point = (qrcode.width / 2) - cross.width / 2
      qrcode.replace!(cross, point, point)
      qrcode.save(file.path, :fast_rgba)
      yield file.path
    end
  end

  def creditor_values
    values = creditor.except(:address_type, :town, :zip, :country)
      .reverse_merge(iban: @invoice.iban)
    striped_values(values).join("\n")
  end

  def debitor_values
    values = debitor.except(:address_type, :town, :zip, :country)
    striped_values(values).join("\n")
  end

  private

  def generate_png # rubocop:disable Metrics/MethodLength
    RQRCode::QRCode.new(payload,  level: :m).as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
    )
  end

  def extract_contact(contactable) # rubocop:disable Metrics/MethodLength
    parts = contactable.strip.to_s.split(/\r*\n/)
    {
      address_type: 'K',
      full_name: parts.first,
      address_line1: parts.second,
      address_line2: parts.third,
      zip_code: nil,
      town: nil,
      country: 'CH'
    }
  end

  def striped_values(*hashes)
    hashes.collect { |obj| obj.values.collect(&:to_s).collect(&:strip) }
  end

  def image(filename)
    Rails.root.join("app/domain/invoice/assets/#{filename}")
  end
end

