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

  enum status: [:draft, :pending, :registered]

  belongs_to :invoice_config

  serialize :encrypted_keys
  serialize :encrypted_password

  attr_encrypted :keys, :password
end
