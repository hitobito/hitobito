#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::Qrcode
  def initialize(invoice)
    @invoice = invoice
    @deprecations = Deprecations.new(invoice)
  end

  # see comment on Export::Pdf::Invoice::PaymentSlipQr#render
  def payload
    striped_values(
      metadata,
      creditor.reverse_merge(iban: @invoice.iban&.gsub(/\s+/, "")),
      creditor_final,
      payment,
      debitor,
      payment_reference,
      additional_infos,
      alternative_payment
    ).join("\r\n")
  end

  def metadata
    {type: "SPC", version: "0200", coding: "1"}
  end

  def creditor
    if @deprecations.deprecated_creditor?
      return @deprecations.creditor
    end

    {
      address_type: "S",
      name: @invoice.payee_name,
      street: @invoice.payee_street,
      housenumber: @invoice.payee_housenumber,
      zip_code: @invoice.payee_zip_code,
      town: @invoice.payee_town,
      country: @invoice.payee_country
    }
  end

  def debitor
    if @deprecations.deprecated_debitor?
      return @deprecations.debitor
    end

    {
      address_type: "S",
      name: @invoice.recipient_company_name.presence || @invoice.recipient_name,
      street: @invoice.recipient_street.presence || @invoice.recipient_postbox,
      # Only show housenumber if recipient_street is present
      housenumber: @invoice.recipient_street.present? ? @invoice.recipient_housenumber : nil,
      zip_code: @invoice.recipient_zip_code,
      town: @invoice.recipient_town,
      country: @invoice.recipient_country
    }
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

  def swiss_cross
    image("CH-Kreuz_7mm.png")
  end

  def png
    RQRCode::QRCode.new(payload, level: :m)
      .as_png(module_px_size: 1, border_modules: 0)
      .to_blob(color_mode: ChunkyPNG::COLOR_GRAYSCALE, bit_depth: 1)
  end

  def formatted_creditor
    [
      @invoice.iban,
      format_address(creditor)
    ].join("\n")
  end

  def formatted_debitor
    format_address debitor
  end

  private

  def image(filename)
    Rails.root.join("app/domain/invoice/assets/#{filename}")
  end

  def show_total?
    !@invoice.hide_total? && @invoice.total.nonzero?
  end

  def format_address(address_attrs)
    if address_attrs[:address_type] == "K"
      [
        address_attrs[:name],
        address_attrs[:address_line1],
        address_attrs[:address_line2]
      ]
    else
      [
        address_attrs[:name],
        [address_attrs[:street], address_attrs[:housenumber]].compact.join(" "),
        [address_attrs[:zip_code], address_attrs[:town]].compact.join(" ")
      ]
    end.compact_blank.join("\n")
  end

  def striped_values(*hashes)
    hashes.collect { |obj| obj.values.collect(&:to_s).collect(&:strip) }
  end
end
