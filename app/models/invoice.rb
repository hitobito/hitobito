# frozen_string_literal: true
#
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoices
#
#  id                          :integer          not null, primary key
#  title                       :string(255)      not null
#  sequence_number             :string(255)      not null
#  state                       :string(255)      default("draft"), not null
#  esr_number                  :string(255)      not null
#  description                 :text(65535)
#  recipient_email             :string(255)
#  recipient_address           :text(65535)
#  sent_at                     :date
#  due_at                      :date
#  group_id                    :integer          not null
#  recipient_id                :integer
#  total                       :decimal(12, 2)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_number              :string(255)
#  address                     :text(65535)
#  issued_at                   :date
#  iban                        :string(255)
#  payment_purpose             :text(65535)
#  payment_information         :text(65535)
#  payment_slip                :string(255)      default("ch_es"), not null
#  beneficiary                 :text(65535)
#  payee                       :text(65535)
#  participant_number          :string(255)
#  creator_id                  :integer
#  participant_number_internal :string(255)
#  vat_number                  :string(255)
#

class Invoice < ActiveRecord::Base
  include I18nEnums
  include PaymentSlips

  ROUND_TO = BigDecimal('0.05')

  SEQUENCE_NR_SEPARATOR = '-'

  STATES = %w(draft issued sent payed reminded cancelled).freeze
  STATES_REMINDABLE = %w(issued sent reminded).freeze
  STATES_PAYABLE = %w(issued sent reminded).freeze

  DUE_SINCE = %w(one_day one_week one_month).freeze

  belongs_to :group
  belongs_to :recipient, class_name: 'Person'
  belongs_to :creator, class_name: 'Person'
  belongs_to :invoice_list, optional: true


  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :payment_reminders, dependent: :destroy

  before_validation :set_sequence_number, on: :create, if: :group
  before_validation :set_esr_number, on: :create, if: :group
  before_validation :set_payment_attributes, on: :create, if: :group
  before_validation :set_reference_number, on: :create, if: :group
  before_validation :set_dates, on: :update
  before_validation :set_self_in_nested
  before_validation :recalculate

  validates :state, inclusion: { in: STATES }
  validates :due_at, timeliness: { after: :sent_at }, presence: true, if: :sent?
  validates :invoice_items, presence: true, if: -> { issued? || sent? }
  validate :assert_sendable?, unless: :recipient_id?
  validates_associated :invoice_config

  before_create :set_recipient_fields, if: :recipient
  after_create :increment_sequence_number


  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  i18n_enum :state, STATES, scopes: true, queries: true

  validates_by_schema

  scope :list,           -> { order_by_sequence_number }
  scope :one_day,        -> { where('invoices.due_at < ?', 1.day.ago.to_date) }
  scope :one_week,       -> { where('invoices.due_at < ?', 1.week.ago.to_date) }
  scope :one_month,      -> { where('invoices.due_at < ?', 1.month.ago.to_date) }
  scope :visible,        -> { where.not(state: :cancelled) }
  scope :remindable,     -> { where(state: STATES_REMINDABLE) }

  class << self
    def draft_or_issued_in(year)
      return all unless year.to_s =~ /\A\d+\z/
      condition = OrCondition.new
      condition.or('EXTRACT(YEAR FROM issued_at) = ?', year)
      condition.or('issued_at IS NULL AND EXTRACT(YEAR FROM invoices.created_at) = ?', year)
      where(condition.to_a)
    end

    def to_contactables(invoices)
      invoices.collect do |invoice|
        next if invoice.recipient_address.blank?
        Person.new(address: invoice.recipient_address)
      end.compact
    end

    def order_by_sequence_number
      order(Arel.sql(order_by_sequence_number_statement.join(', ')))
    end

    # Orders by first integer, second integer
    def order_by_sequence_number_statement
      %w(sequence_number).product(%w(1 -1)).map do |field, index|
        "CAST(SUBSTRING_INDEX(#{field}, '-', #{index}) AS UNSIGNED)"
      end
    end
  end

  def calculated
    [:total, :cost, :vat].collect do |field|
      [field, round(invoice_items.reject(&:frozen?).sum(&field))]
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

  def payable?
    STATES_PAYABLE.include?(state)
  end

  def recipient_name
    recipient.try(:greeting_name) || recipient_name_from_recipient_address
  end

  def filename(extension = 'pdf')
    format('%s-%s.%s', self.class.model_name.human, sequence_number, extension)
  end

  def invoice_config
    group.invoice_config
  end

  def state
    ActiveSupport::StringInquirer.new(self[:state])
  end

  def amount_open(without: nil)
    total - payments.where.not(id: without).sum(:amount)
  end

  def amount_paid
    payments.sum(:amount)
  end

  def overdue?
    due_at && due_at < Time.zone.today
  end

  def qrcode
    @qrcode ||= Invoice::Qrcode.new(self)
  end

  private

  def set_self_in_nested
    invoice_items.each { |item| item.invoice = self }
  end

  def set_sequence_number
    self.sequence_number = [group_id, invoice_config.sequence_number].join(SEQUENCE_NR_SEPARATOR)
  end

  def set_esr_number
    self.esr_number = Invoice::PaymentSlip.new(self).esr_number
  end

  def set_reference_number
    self.reference = Invoice::Reference.create(self)
  end

  def set_payment_attributes
    [:address, :account_number, :iban, :payment_slip,
     :beneficiary, :payee, :participant_number,
     :participant_number_internal, :vat_number, :currency].each do |at|
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
    self.recipient_address = recipient.address_for_letter
  end

  def item_invalid?(attributes)
    !InvoiceItem.new(attributes.merge(invoice: self)).valid?
  end

  def increment_sequence_number
    invoice_config.increment!(:sequence_number) # rubocop:disable Rails/SkipsModelValidations
  end

  def recipient_name_from_recipient_address
    recipient_address.to_s.split("\n").first.presence
  end

  def assert_sendable?
    if recipient_email.blank? && recipient_address.blank?
      errors.add(:base, :recipient_address_or_email_required)
    end
  end

  def round(decimal)
    (decimal / ROUND_TO).round * ROUND_TO
  end
end
