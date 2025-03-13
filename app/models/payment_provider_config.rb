# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: payment_provider_configs
#
#  id                 :bigint           not null, primary key
#  encrypted_keys     :text
#  encrypted_password :string
#  partner_identifier :string
#  payment_provider   :string
#  status             :integer          default("draft"), not null
#  synced_at          :datetime
#  user_identifier    :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  invoice_config_id  :bigint
#
# Indexes
#
#  index_payment_provider_configs_on_invoice_config_id  (invoice_config_id)
#

class PaymentProviderConfig < ActiveRecord::Base
  include Encryptable
  include I18nEnums

  enum status: {draft: 0, pending: 1, registered: 2}
  i18n_enum :payment_provider, Settings.payment_providers.map(&:name)

  belongs_to :invoice_config

  serialize :encrypted_keys, coder: YAML
  serialize :encrypted_password, coder: YAML

  scope :initialized, -> { where(status: [:pending, :registered]) }

  after_destroy :clear_scheduled_ebics_import_jobs

  attr_encrypted :keys, :password

  def empty?
    partner_identifier.blank? && user_identifier.blank?
  end

  def with_payment_provider(provider)
    self.payment_provider = provider
  end

  def ebics_required_fields_present?
    payment_provider.present? &&
      user_identifier.present? &&
      partner_identifier.present? &&
      password.present?
  end

  def clear_scheduled_ebics_import_jobs
    Delayed::Job.where("handler LIKE '%Payments::EbicsImportJob%payment_provider_config_id: ?%'", id).delete_all
  end
end
