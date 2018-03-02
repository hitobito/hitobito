class PaymentReminderConfig < ActiveRecord::Base
  belongs_to :invoice_config

  validates_by_schema

  validates :level, length: { in: (1..3) }

  scope :list, -> { order(:level) }

end
