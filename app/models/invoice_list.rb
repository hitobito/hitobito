# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


class InvoiceList < ActiveRecord::Base
  belongs_to :group
  belongs_to :receiver, polymorphic: true
  belongs_to :creator, class_name: 'Person'
  has_many :invoices, dependent: :destroy

  attr_accessor :recipient_ids, :invoice
  validates :receiver_type, inclusion: %w(MailingList), allow_blank: true

  validates_by_schema

  def invoice_parameters
    invoice_item_attributes = invoice.invoice_items.collect { |item| item.attributes.compact }
    invoice.attributes.compact.merge(invoice_items_attributes: invoice_item_attributes)
  end

  def update_paid
    update(amount_paid: invoices.sum(&:amount_paid), recipients_paid: invoices.payed.count)
  end

  def receiver_label
    "#{receiver} (#{receiver.model_name.human})"
  end

  def recipient_ids_count
    if receiver
      receiver.people.unscope(:select).count
    else
      recipient_ids.split(',').count
    end
  end

  def first_recipient
    if receiver
      receiver.people.first
    else
      Person.find(recipient_ids.split(',').first)
    end
  end

  def recipients
    if receiver
      receiver.people
    else
      Person.where(id: recipient_ids.split(','))
    end
  end
end
