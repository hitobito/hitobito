class MadeRequiredInvoiceNotificationPlaceholdersOptional < ActiveRecord::Migration[4.2]

  PLACEHOLDERS_REQUIRED = 'invoice-items, invoice-total, payment-information'
  PLACEHOLDERS_OPTIONAL = 'recipient-name, group-name, group-address, invoice-number'

  def up
    return unless invoice_notification_content
    placeholders_optional = [PLACEHOLDERS_OPTIONAL, PLACEHOLDERS_REQUIRED].join(', ')

    say_with_time('update placeholders to be optional') do
      invoice_notification_content.update(placeholders_optional: placeholders_optional,
                                          placeholders_required: '')
    end
  end

  def down
    return unless invoice_notification_content
    say_with_time('update some placeholders to be required') do
      invoice_notification_content.update(placeholders_optional: PLACEHOLDERS_OPTIONAL,
                                          placeholders_required: PLACEHOLDERS_REQUIRED)
    end
  end

  private

  def invoice_notification_content
    CustomContent.find_by(key: 'content_invoice_notification')
  end

end
