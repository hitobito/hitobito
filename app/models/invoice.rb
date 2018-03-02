# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoices
#
#  id                :integer          not null, primary key
#  title             :string(255)      not null
#  sequence_number   :string(255)      not null
#  state             :string(255)      default("draft"), not null
#  esr_number        :string(255)      not null
#  description       :text(65535)
#  recipient_email   :string(255)
#  recipient_address :text(65535)
#  sent_at           :date
#  due_at            :date
#  group_id          :integer          not null
#  recipient_id      :integer          not null
#  total             :decimal(12, 2)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Invoice < ActiveRecord::Base
  include I18nEnums
  include PaymentSlips

  attr_accessor :recipient_ids

  STATES = %w(draft issued sent payed reminded cancelled).freeze
  STATES_REMINDABLE = %w(issued sent reminded).freeze

  DUE_SINCE = %w(one_day one_week one_month).freeze

  belongs_to :group
  belongs_to :recipient, class_name: 'Person'
  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :payment_reminders, dependent: :destroy

  before_validation :set_sequence_number, on: :create, if: :group
  before_validation :set_esr_number, on: :create, if: :group
  before_validation :set_payment_attributes, on: :create, if: :group
  before_validation :set_dates, on: :update
  before_validation :set_self_in_nested
  before_validation :recalculate

  validates :state, inclusion: { in: STATES }
  validates :due_at, timeliness: { after: :sent_at }, presence: true, if: :sent?
  validate :assert_sendable?, unless: :recipient_id?
  validates_associated :invoice_config

  before_create :set_recipient_fields, if: :recipient
  after_create :increment_sequence_number


  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  i18n_enum :state, STATES

  validates_by_schema

  scope :list,           -> { order(:sequence_number) }
  scope :one_day,        -> { where('invoices.due_at < ?', 1.day.ago.to_date) }
  scope :one_week,       -> { where('invoices.due_at < ?', 1.week.ago.to_date) }
  scope :one_month,      -> { where('invoices.due_at < ?', 1.month.ago.to_date) }
  scope :visible,        -> { where.not(state: :cancelled) }
  scope :remindable,     -> { where(state: STATES_REMINDABLE) }

  STATES.each do |state|
    scope state.to_sym, -> { where(state: state) }
    define_method "#{state}?" do
      self.state == state
    end
  end

  def self.to_contactables(invoices)
    invoices.collect do |invoice|
      next if invoice.recipient_address.blank?
      Person.new(address: invoice.recipient_address)
    end.compact
  end

  def multi_create
    Invoice.transaction do
      recipients.all? do |recipient|
        invoice = self.class.new(multi_create_attributes(recipient))
        invoice.save
      end || (raise ActiveRecord::Rollback)
    end
  end

  def calculated
    [:total, :cost, :vat].collect do |field|
      [field, invoice_items.reject(&:frozen?).sum(&field)]
    end.to_h
  end

  def recalculate
    self.total = calculated[:total] || 0
  end

  def recalculate!
    update_attribute(:total, calculated[:total] || 0)
  end

  def to_s
    "#{title}(#{sequence_number}): #{total}"
  end

  def remindable?
    STATES_REMINDABLE.include?(state)
  end

  def recipients
    Person.where(id: recipient_ids.to_s.split(','))
  end

  def recipient_name
    recipient.try(:greeting_name) || recipient_address.split("\n").first
  end

  def filename(extension)
    format('%s-%s.%s', self.class.model_name.human, sequence_number, extension)
  end

  def invoice_config
    group.invoice_config
  end

  def state
    ActiveSupport::StringInquirer.new(self[:state])
  end

  def amount_open
    total - payments.sum(:amount)
  end

  def amount_paid
    payments.sum(:amount)
  end

  private

  def multi_create_attributes(recipient)
    attributes.merge(
      invoice_items_attributes: invoice_items.collect(&:attributes),
      recipient_id: recipient.id
    )
  end

  def set_self_in_nested
    invoice_items.each { |item| item.invoice = self }
  end

  def set_sequence_number
    self.sequence_number = [group_id, invoice_config.sequence_number].join('-')
  end

  def set_esr_number
    self.esr_number = Invoice::PaymentSlip.new(self).esr_number
  end

  def set_payment_attributes
    [:address, :account_number, :iban,
     :payment_slip, :beneficiary, :payee, :participant_number].each do |at|
      assign_attributes(at => invoice_config.send(at))
    end
  end

  def set_dates
    self.sent_at ||= Time.zone.today if sent?
    if sent? || issued?
      self.issued_at ||= Time.zone.today
      self.due_at ||= issued_at + invoice_config.due_days.days
    end
  end

  def set_recipient_fields
    self.recipient_email = recipient.email
    self.recipient_address = build_recipient_address
  end

  def item_invalid?(attributes)
    !InvoiceItem.new(attributes.merge(invoice: self)).valid?
  end

  def increment_sequence_number
    invoice_config.increment!(:sequence_number) # rubocop:disable Rails/SkipsModelValidations
  end

  def build_recipient_address
    [recipient.full_name,
     recipient.address,
     [recipient.zip_code, recipient.town].compact.join(' / '),
     recipient.country].compact.join("\n")
  end

  def assert_sendable?
    if recipient_email.blank? && recipient_address.blank?
      errors.add(:base, :recipient_address_or_email_required)
    end
  end
end
