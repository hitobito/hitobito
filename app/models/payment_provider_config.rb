# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: payment_provider_configs
#
#  id                        :integer          not null, primary key
#  payment_provider          :string(255)
#  invoice_config_id         :integer
#  status                    :integer          default(0)
#  partner_identifier        :string(255)
#  user_identifier           :string(255)
#  encrypted_password        :string(255)
#  encrypted_keys            :text(16777215)
#  synced_at                 :datetime
#  created_at                :datetime
#  updated_at                :datetime
#

class PaymentProviderConfig < ActiveRecord::Base
  include Encryptable
  include I18nEnums

  enum status: [:draft, :pending, :registered]
  i18n_enum :payment_provider, Settings.payment_providers.map(&:name)

  belongs_to :invoice_config

  serialize :encrypted_keys
  serialize :encrypted_password

  scope :initialized, -> { where(status: [:pending, :registered]) }

  attr_encrypted :keys, :password

  def with_payment_provider(provider)
    self.payment_provider = provider
  end

  def ebics_required_fields_present?
    payment_provider.present? &&
      user_identifier.present? &&
      partner_identifier.present? &&
      password.present?
  end
end
