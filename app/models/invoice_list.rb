# frozen_string_literal: true

#  Copyright (c) 2022-2024, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

# == Schema Information
#
# Table name: invoice_lists
#
#  id                    :bigint           not null, primary key
#  amount_paid           :decimal(15, 2)   default(0.0), not null
#  amount_total          :decimal(15, 2)   default(0.0), not null
#  invalid_recipient_ids :text
#  receiver_type         :string
#  recipient_ids         :text
#  recipients_paid       :integer          default(0), not null
#  recipients_processed  :integer          default(0), not null
#  recipients_total      :integer          default(0), not null
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  creator_id            :bigint
#  group_id              :bigint
#  receiver_id           :bigint
#
# Indexes
#
#  index_invoice_lists_on_creator_id                     (creator_id)
#  index_invoice_lists_on_group_id                       (group_id)
#  index_invoice_lists_on_receiver_type_and_receiver_id  (receiver_type,receiver_id)
#

class InvoiceList < ActiveRecord::Base
  serialize :recipient_ids, type: Array, coder: YAML
  serialize :invalid_recipient_ids, type: Array, coder: YAML
  belongs_to :group
  belongs_to :receiver, polymorphic: true
  belongs_to :creator, class_name: "Person"
  has_one :invoice, dependent: :destroy
  has_one :message, dependent: :nullify
  has_many :invoices, dependent: :destroy

  attr_accessor :invoice

  validates :receiver_type, inclusion: %w[MailingList Group], allow_blank: true

  scope :list, -> { order(:created_at) }

  validates_by_schema except: :invalid_recipient_ids

  def to_s
    title
  end

  def invoice_parameters
    invoice_item_attributes = invoice.invoice_items.collect { |item| item.attributes.compact }
    invoice.attributes.compact.merge(invoice_items_attributes: invoice_item_attributes)
  end

  def update_paid
    update(amount_paid: invoices.joins(:payments).sum("payments.amount"),
      recipients_paid: invoices.where(state: [:payed, :excess]).count)
  end

  def update_total
    total_sum = invoices.visible.sum(&:total)
    total_count = invoices.visible.pluck(:recipient_id).count
    update(amount_total: total_sum, recipients_total: total_count)
  end

  def receiver_label
    "#{receiver} (#{receiver.model_name.human})"
  end

  def recipient_ids_count
    receiver ? receiver.people.unscope(:select).count : recipient_ids.count
  end

  def first_recipient
    receiver ? receiver.people.first : Person.find(recipient_ids.first)
  end

  def recipients
    receiver ? receiver.people : Person.where(id: recipient_ids)
  end

  def invoice_config
    group.layer_group.invoice_config
  end

  def recipient_ids=(ids)
    value = ids.is_a?(Array) ? ids : ids.to_s.scan(/\d+/).map(&:to_i).select(&:positive?)
    write_attribute(:recipient_ids, value)
  end
end
