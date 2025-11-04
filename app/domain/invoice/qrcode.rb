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

  QR_CODE_VALUES_KEYS = [:address_type, :full_name, :street, :housenumber, :zip_code,
    :town, :country]

  def initialize(invoice)
    @invoice = invoice
  end

  # https://www.six-group.com/dam/download/banking-services/standardization/qr-bill/ig-qr-bill-v2.3-de.pdf
  # see "4.2.2 Datenelemente in der QR-Rechnung"
  def payload
    striped_values(
      metadata,
      creditor.to_h.reverse_merge(iban: @invoice.iban&.gsub(/\s+/, "")),
      creditor_final,
      payment,
      debitor.to_h,
      payment_reference,
      additional_infos,
      alternative_payment
    ).join("\r\n")
  end

  def metadata
    {type: "SPC", version: "0200", coding: "1"}
  end

  def creditor
    @creditor ||= Invoice::QrcodeAddress.new(@invoice.qr_code_creditor_values)
  end

  def debitor
    @debitor ||= Invoice::QrcodeAddress.new(@invoice.qr_code_debitor_values)
  end

  def creditor_final
    debitor.to_h.keys.product([nil]).to_h # optional, mock with nil values
  end

  def payment
    amount = format("%<total>.2f", total: @invoice.amount_open) if show_total?
    {amount: amount, currency: @invoice.currency}
  end

  def payment_reference
    # If the reference is blank, we use the type "NON".
    # Currently only occuring in SAC wagon.
    type = if @invoice.reference.blank?
      "NON"
    elsif @invoice.reference.starts_with?("RF")
      "SCOR"
    else
      "QRR"
    end
    {type: type, reference: @invoice.reference}
  end

  def additional_infos
    {
      purpose: @invoice.payment_purpose.to_s.tr("\n", " ").truncate(120),
      trailer: "EPD",
      infos: nil
    }
  end

  def alternative_payment
    {type: nil}
  end

  def scissor(kind)
    image("schere_#{kind}.png")
  end

  def generate
    Tempfile.create([@invoice.sequence_number, ".png"], binmode: true) do |file|
      qrcode = generate_png
      cross = ChunkyPNG::Image.from_file(image("CH-Kreuz_7mm_small.png"))
      point = (qrcode.width / 2) - cross.width / 2
      qrcode.replace!(cross, point, point)
      qrcode.save(file.path, :fast_rgba)
      yield file.path
    end
  end

  private

  def generate_png # rubocop:disable Metrics/MethodLength
    RQRCode::QRCode.new(payload, level: :m).as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false
    )
  end

  def striped_values(*hashes)
    hashes.collect { |obj| obj.values.collect(&:to_s).collect(&:strip) }
  end

  def image(filename)
    Rails.root.join("app/domain/invoice/assets/#{filename}")
  end

  def show_total?
    !@invoice.hide_total? && @invoice.total.nonzero?
  end
end
