# == Schema Information
#
# Table name: payment_reminder_configs
#
#  id                :integer          not null, primary key
#  invoice_config_id :integer          not null
#  title             :string(255)      not null
#  text              :string(255)      not null
#  due_days          :integer          not null
#  level             :integer          not null
#

class PaymentReminderConfig < ActiveRecord::Base
  belongs_to :invoice_config

  validates_by_schema

  validates :level, length: { in: (1..3) }

  scope :list, -> { order(:level) }

end
