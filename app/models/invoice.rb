# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: invoices
#
#  id                  :integer          not null, primary key
#  account_number      :string
#  address             :text
#  beneficiary         :text
#  currency            :string           default("CHF"), not null
#  description         :text
#  due_at              :date
#  esr_number          :string           not null
#  hide_total          :boolean          default(FALSE), not null
#  iban                :string
#  issued_at           :date
#  participant_number  :string
#  payee               :text
#  payment_information :text
#  payment_purpose     :text
#  payment_slip        :string           default("ch_es"), not null
#  recipient_address   :text
#  recipient_email     :string
#  reference           :string           not null
#  sent_at             :date
#  sequence_number     :string           not null
#  state               :string           default("draft"), not null
#  title               :string           not null
#  total               :decimal(12, 2)
#  vat_number          :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  creator_id          :integer
#  group_id            :integer          not null
#  invoice_run_id     :bigint
#  recipient_id        :integer
#
# Indexes
#
#  index_invoices_on_esr_number       (esr_number)
#  index_invoices_on_group_id         (group_id)
#  index_invoices_on_invoice_run_id  (invoice_run_id)
#  index_invoices_on_recipient_id     (recipient_id)
#  index_invoices_on_sequence_number  (sequence_number)
#

class Invoice < ActiveRecord::Base # rubocop:todo Metrics/ClassLength
  SEARCHABLE_ATTRS = [:title, :reference, :sequence_number,
    {invoice_items: [:name, :account, :cost_center]}]

  include I18nEnums
  include PaymentSlips
  include FullTextSearchable

  ROUND_TO = BigDecimal("0.05")

  SEQUENCE_NR_SEPARATOR = "-"

  # rubocop:disable Style/MutableConstant meant to be extended in wagons
  STATES = %w[draft issued sent partial payed excess reminded cancelled]
  STATES_REMINDABLE = %w[issued sent partial reminded]
  STATES_PAYABLE = %w[issued sent partial reminded]

  DUE_SINCE = %w[one_day one_week one_month]
  # rubocop:enable Style/MutableConstant meant to be extended in wagons

  QR_ID_RANGE = (30_000..31_999)

  belongs_to :group
  belongs_to :recipient, polymorphic: true
  belongs_to :creator, class_name: "Person"
  belongs_to :invoice_run, optional: true

  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :payment_reminders, dependent: :destroy

  before_validation :set_sequence_number, on: :create, if: :group
  before_validation :set_payment_attributes, on: :create, if: :group
  before_validation :set_esr_number, on: :create, if: :group
  before_validation :set_reference_number, on: :create, if: :group
  before_validation :set_dates, on: :update
  before_validation :set_self_in_nested
  before_validation :recalculate
  before_validation :set_recipient_fields, on: :create, if: :recipient

  validates :state, inclusion: {in: STATES}
  validates :due_at, timeliness: {after: :sent_at}, presence: true, if: :sent?
  validates :invoice_items, presence: true, if: -> { (issued? || sent?) && !invoice_run }
  validates :title, presence: true
  # In external invoices, the recipient type may also be blank
  validates :recipient_type, inclusion: {in: ["Person", "Group"]}, allow_blank: true
  validate :recipient_name_present?
  validates :recipient_street, :recipient_zip_code, :recipient_town, :recipient_country,
    presence: true, unless: :tolerate_deprecated_recipient_address?
  validate :assert_sendable?, unless: :recipient_id?

  normalizes :recipient_email, with: ->(attribute) { attribute.downcase }

  after_create :increment_sequence_number

  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  # To generate invoice pdfs with custom data, allow setting these attributes manually.
  # Used by sac_cas wagon.
  attr_writer :invoice_config, :letter_address_position

  i18n_enum :state, STATES, scopes: true, queries: true

  validates_by_schema

  scope :list, -> { order_by_sequence_number }
  scope :one_day, -> { where(invoices: {due_at: ...1.day.ago.to_date}) }
  scope :one_week, -> { where(invoices: {due_at: ...1.week.ago.to_date}) }
  scope :one_month, -> { where(invoices: {due_at: ...1.month.ago.to_date}) }
  scope :visible, -> { where.not(state: :cancelled) }
  scope :remindable, -> { where(state: STATES_REMINDABLE) }
  scope :standalone, -> { where(invoice_run_id: nil) }
  scope :with_recipients, -> { extending(PreloadRecipients) }

  class << self
    def with_aggregated_payments
      # rubocop:todo Layout/LineLength
      select("invoices.*, last_payment_at, COALESCE(amount_paid, 0) AS amount_paid, true as joined_payments")
        # rubocop:enable Layout/LineLength
        .joins(Invoice.last_payments_information)
    end

    def draft_or_issued_in(year)
      return all unless /\A\d+\z/.match?(year.to_s)

      draft_or_issued(from: Date.new(year, 1, 1), to: Date.new(year, 12, 31))
    end

    def draft_or_issued(from:, to:)
      from = Date.parse(from.to_s).beginning_of_day rescue DateTime.current.beginning_of_year # rubocop:disable Style/RescueModifier
      to = Date.parse(to.to_s).end_of_day rescue DateTime.current.end_of_year # rubocop:disable Style/RescueModifier

      condition = OrCondition.new
      condition.or("issued_at >= :from AND issued_at <= :to", from: from, to: to)
      condition.or("issued_at IS NULL AND " \
                   "invoices.created_at >= :from AND invoices.created_at <= :to",
        from: from, to: to)
      where(condition.to_a)
    end

    def order_by_sequence_number
      order(Arel.sql(order_by_sequence_number_statement.join(", ")))
    end

    # Orders by first integer, second integer
    def order_by_sequence_number_statement
      %w[sequence_number].product(%w(^[^-]+ [^-]+$)).map do |field, index|
        "CAST(SUBSTRING(#{field} FROM '#{index}') AS INTEGER)"
      end
    end

    def order_by_payment_statement
      "last_payments.last_payment_at"
    end

    def order_by_amount_paid_statement
      "last_payments.amount_paid"
    end

    def last_payments_information
      <<~SQL.squish
        LEFT OUTER JOIN (
          SELECT invoice_id,
                 MAX(received_at) AS last_payment_at,
                 SUM(amount) AS amount_paid
          FROM payments
          GROUP BY invoice_id
        ) AS last_payments ON invoices.id = last_payments.invoice_id
      SQL
    end
  end

  delegate :logo_position, to: :invoice_config

  def calculated
    InvoiceItems::Calculation.new.calculate_total_cost_and_vat(invoice_items)
  end

  def recalculate
    self.total = calculated[:total] || 0
  end

  def recalculate!
    update_attribute(:total, calculated[:total] || 0) # rubocop:disable Rails/SkipsModelValidations
    invoice_run&.update_total
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

  def payed?
    state.payed? || state.excess?
  end

  def includes_dynamic_invoice_items?
    invoice_items.any?(&:dynamic)
  end

  def filename(extension = "pdf")
    format("%<type>s-%<number>s.%<ext>s",
      type: self.class.model_name.human,
      number: sequence_number,
      ext: extension)
  end

  def invoice_config
    @invoice_config ||= group.layer_group.invoice_config
  end

  def letter_address_position
    @letter_address_position || group.letter_address_position
  end

  def state
    ActiveSupport::StringInquirer.new(self[:state])
  end

  def amount_open(without: nil)
    total - payments.where.not(id: without).sum(:amount)
  end

  def amount_paid
    joined_payments? ? read_attribute(:amount_paid) : payments.sum(:amount)
  end

  def last_payment_at
    joined_payments? ? read_attribute(:last_payment_at) : payments.last&.received_at
  end

  def overdue?
    due_at && due_at < Time.zone.today
  end

  def qrcode
    @qrcode ||= Invoice::Qrcode.new(self)
  end

  def qr_without_qr_iban?
    iban && qr? && !QR_ID_RANGE.include?(qr_id)
  end

  def latest_reminder
    payment_reminders.max_by(&:created_at)
  end

  def recipient_address
    if recipient_address_values.empty?
      deprecated_recipient_address
    else
      recipient_address_values.join("\n")
    end
  end

  def recipient_address_values
    [
      recipient_company_name,
      recipient_name,
      recipient_address_values_without_name
    ].flatten.uniq.compact_blank
  end

  def recipient_address_values_without_name
    [
      recipient_address_care_of,
      recipient_street_with_housenumber,
      recipient_postbox,
      recipient_town_with_zip_code,
      ((recipient_country == Settings.countries.prioritized.first) ? nil : recipient_country)
    ].uniq.compact_blank
  end

  def recipient_street_with_housenumber
    [recipient_street, recipient_housenumber].compact_blank.join(" ")
  end

  def recipient_town_with_zip_code
    [recipient_zip_code, recipient_town].compact_blank.join(" ")
  end

  def payee
    if payee_address_values.empty?
      deprecated_payee
    else
      payee_address_values.join("\n")
    end
  end

  def payee_address_values
    [
      payee_name,
      payee_street_with_housenumber,
      payee_town_with_zip_code
    ].compact_blank
  end

  def payee_street_with_housenumber
    [payee_street, payee_housenumber].compact_blank.join(" ")
  end

  def payee_town_with_zip_code
    [payee_zip_code, payee_town].compact_blank.join(" ")
  end

  private

  # on index we join aggregated payments
  def joined_payments?
    self[:joined_payments]
  end

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
    assign_attributes(
      invoice_config.slice(
        :address, :account_number, :iban, :payment_slip, :beneficiary,
        :participant_number, :vat_number, :currency, :payee_name, :payee_street,
        :payee_housenumber, :payee_zip_code, :payee_town, :payee_country
      )
    )
  end

  def set_dates # rubocop:disable Metrics/CyclomaticComplexity
    self.sent_at ||= Time.zone.today if sent?
    if sent? || issued?
      self.issued_at ||= Time.zone.today
      self.due_at ||= issued_at + invoice_config.due_days.days
    end
  end

  def set_recipient_fields!
    self.recipient_email = invoice_email

    attributes = Contactable::Address.new(recipient).invoice_recipient_address_attributes
    assign_attributes(attributes)
  end

  def set_recipient_fields
    self.recipient_email ||= invoice_email

    attributes = Contactable::Address.new(recipient).invoice_recipient_address_attributes
    assign_attributes(attributes.select { |key, _| send(key).nil? })
  end

  def item_invalid?(attributes)
    !InvoiceItem.new(attributes.merge(invoice: self)).valid?
  end

  def increment_sequence_number
    invoice_config.increment!(:sequence_number) # rubocop:disable Rails/SkipsModelValidations
  end

  def assert_sendable?
    # This assertion only makes sense for old invoices,
    # since for new invoices, recipient_address_values must be set
    return unless persisted?
    return if recipient_address_values.any?

    if recipient_email.blank? && deprecated_recipient_address.blank?
      errors.add(:base, :recipient_address_or_email_required)
    end
  end

  def recipient_name_present?
    if recipient_name.blank? && recipient_company_name.blank?
      errors.add(:base, :recipient_name_or_company_name_required)
    end
  end

  def tolerate_deprecated_recipient_address?
    issued_at&.year == 2025 && recipient.nil? && recipient_address_values_without_name.blank?
  end

  def qr_id
    iban.delete(" ")[4..8].to_i
  end

  def invoice_email
    recipient.additional_emails.find(&:invoices?)&.email || recipient.email
  end
end
