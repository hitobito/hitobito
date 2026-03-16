#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::ReadPaymentProcessJob < AsyncRenderBaseJob
  self.parameters = [:locale, :user_id, :target_dom_id, :group_id, :xml_file_id, :options]

  attr_reader :group_id, :xml_file_id

  def initialize(user_id, target_dom_id, group_id, xml_file_id, options = {})
    super(user_id, target_dom_id, options)
    @group_id = group_id
    @xml_file_id = xml_file_id
  end

  def partial_name
    "payment_processes/preview_table"
  end

  def data
    {
      group: group,
      from: processor.from,
      to: processor.to,
      valid_payments_without_invoice: processor.valid_payments_without_invoice,
      invalid_payments: processor.invalid_payments,
      valid_payments_with_invoice: processor.valid_payments_with_invoice,
      valid_payments: processor.valid_payments,
      xml_file_id: xml_file_id
    }
  end

  private

  def processor = @processor ||= Invoice::PaymentProcessor.new(xml_file.download)

  def xml_file = @xml_file ||= ActiveStorage::Blob.find(xml_file_id)

  def group = @group ||= Group.find(group_id)
end
