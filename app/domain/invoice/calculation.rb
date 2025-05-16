class Invoice::Calculation
  attr_reader :invoice_items

  def initialize(invoice_items)
    @invoice_items = invoice_items
  end

  def calculated
    @calculated ||= [:total, :cost, :vat].index_with do |field|
      round(invoice_items.reject(&:frozen?).map(&field).compact.sum(BigDecimal("0.00")))
    end
  end

  def round(decimal)
    (decimal / Invoice::ROUND_TO).round * Invoice::ROUND_TO
  end
end
