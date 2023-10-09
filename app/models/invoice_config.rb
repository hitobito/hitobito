# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: invoice_configs
#
#  id                               :integer          not null, primary key
#  account_number                   :string(255)
#  address                          :text(16777215)
#  beneficiary                      :text(16777215)
#  currency                         :string(255)      default("CHF"), not null
#  due_days                         :integer          default(30), not null
#  email                            :string(255)
#  iban                             :string(255)
#  participant_number               :string(255)
#  participant_number_internal      :string(255)
#  payee                            :text(16777215)
#  payment_information              :text(16777215)
#  payment_slip                     :string(255)      default("ch_es"), not null
#  sequence_number                  :integer          default(1), not null
#  vat_number                       :string(255)
#  donation_calculation_year_amount :integer
#  donation_increase_percentage     :integer
#  vat_number                       :string(255)
#  group_id                         :integer          not null
#
# Indexes
#
#  index_invoice_configs_on_group_id  (group_id)
#

class InvoiceConfig < ActiveRecord::Base
  include I18nEnums
  include ValidatedEmail

  IBAN_REGEX = /\A[A-Z]{2}[0-9]{2}\s?([A-Z]|[0-9]\s?){12,30}\z/.freeze
  ACCOUNT_NUMBER_REGEX = /\A[0-9]{2}-[0-9]{2,20}-[0-9]\z/.freeze
  PARTICIPANT_NUMBER_INTERNAL_REGEX = /\A[0-9]{6}\z/.freeze
  PAYMENT_SLIPS = %w(qr no_ps).freeze
  LOGO_MAX_DIMENSION = Settings.application.image_upload.max_dimension

  class_attribute :logo_positions, default: %w[disabled left right]

  i18n_enum :payment_slip, PAYMENT_SLIPS, scopes: true, queries: true
  i18n_enum :logo_position, scopes: false, queries: false do
    logo_positions.map(&:to_s)
  end

  belongs_to :group, class_name: 'Group'

  has_one_attached :logo
  has_many :payment_reminder_configs, dependent: :destroy
  has_many :payment_provider_configs, dependent: :destroy

  before_validation :nullify_participant_number_internal

  validates :group_id, uniqueness: true
  validates :payee, presence: true, on: :update
  validates :email, format: Devise.email_regexp, allow_blank: true

  # TODO: probably the if condition is not correct, verification needed
  validates :iban, presence: true, on: :update, if: :qr?
  validates :iban, format: { with: IBAN_REGEX },
                   on: :update, allow_blank: true

  validates :donation_calculation_year_amount, numericality: { only_integer: true,
                                                               greater_than: 0,
                                                               allow_nil: true }
  validates :donation_increase_percentage, numericality: { greater_than: 0,
                                                           allow_nil: true }

  validates :logo, attached: {message: :attached_unless_disabled}, if: :logo_enabled?
  validates :logo, dimension: { max: LOGO_MAX_DIMENSION..LOGO_MAX_DIMENSION }
  validates :logo_position, inclusion: { in: ->(_){logo_positions} }

  validate :correct_check_digit
  validate :correct_payee_qr_format, if: :qr?

  validates :sender_name, format: { without: Devise.email_regexp }

  accepts_nested_attributes_for :payment_reminder_configs
  accepts_nested_attributes_for :payment_provider_configs

  validates_by_schema

  def to_s
    model_name.human
  end

  def remove_logo
    false
  end

  def remove_logo=(deletion_param)
    if %w(1 yes true).include?(deletion_param.to_s.downcase)
      logo.purge_later
    end
  end

  def variable_donation_configured?
    self.donation_calculation_year_amount.present? &
      self.donation_increase_percentage.present?
  end

  private

  def correct_address_wordwrap
    return if payee.to_s.split(/\n/).length <= 2

    errors.add(:payee, :to_long)
  end

  def correct_check_digit
    return if account_number.blank?

    payment_slip = Invoice::PaymentSlip.new
    splitted = account_number.delete('-').split('')
    check_digit = splitted.pop

    return if payment_slip.check_digit(splitted.join) == check_digit.to_i

    errors.add(:account_number, :invalid_check_digit)
  end

  def correct_payee_qr_format
    return if payee&.lines&.select(&:present?)&.size&.== 3

    errors.add(:payee, :must_have_3_lines)
  end

  def nullify_participant_number_internal
    self.participant_number_internal = nil
  end

  def logo_enabled?
    logo_position.present? &&
      logo_position != 'disabled'
  end
end
