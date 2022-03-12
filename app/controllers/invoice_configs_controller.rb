# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceConfigsController < CrudController

  self.nesting = Group
  self.permitted_attrs = [:payment_information, :address, :iban, :account_number,
                          :payment_slip, :beneficiary, :payee, :participant_number,
                          :participant_number_internal, :email, :vat_number, :currency,
                          :due_days,
                          :donation_calculation_year_amount, :donation_increase_percentage,
                          payment_reminder_configs_attributes: [
                            :id, :title, :text, :level, :due_days
                          ],
                          payment_provider_configs_attributes: [
                            :id, :payment_provider, :user_identifier, :partner_identifier, :password
                          ]]

  before_render_form :build_payment_reminder_configs
  before_render_form :build_payment_provider_configs

  before_save :define_changed_payment_provider_configs
  after_save :initialize_payment_providers

  private

  def build_entry
    parent.invoice_config
  end

  def find_entry
    parent.invoice_config
  end

  def path_args(_)
    [parent, :invoice_config]
  end

  def build_payment_reminder_configs
    missing_payment_reminder_levels.each do |level|
      entry.payment_reminder_configs.build.with_defaults(level)
    end
  end

  def build_payment_provider_configs
    missing_payment_providers.each do |provider|
      entry.payment_provider_configs.build.with_payment_provider(provider)
    end
  end

  def missing_payment_reminder_levels
    PaymentReminderConfig::LEVELS.to_a - entry.payment_reminder_configs.collect(&:level)
  end

  def missing_payment_providers
    Settings.payment_providers.map(&:name) - entry.payment_provider_configs.map(&:payment_provider)
  end

  def define_changed_payment_provider_configs
    @changed_payment_provider_configs = entry.payment_provider_configs.select do |config|
      config.changed? &&
        config.ebics_required_fields_present?
    end
  end

  def initialize_payment_providers
    @changed_payment_provider_configs.each do |config|
      provider = PaymentProvider.new(config)

      provider.initial_setup

      begin
        provider.INI
        provider.HIA

        config.update!(status: :pending)

        flash[:notice] = t('.flash.provider_initialization_succeeded',
                           payment_provider: config.payment_provider_label)
      rescue Epics::Error::TechnicalError
        flash[:alert] = t('.flash.provider_initialization_failed',
                          payment_provider: config.payment_provider_label)
      end
    end
  end
end
