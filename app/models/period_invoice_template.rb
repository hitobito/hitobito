#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplate < ActiveRecord::Base
  belongs_to :group

  has_many :invoice_runs, dependent: :nullify

  has_many :items, dependent: :destroy, class_name: 'PeriodInvoiceTemplate::Item',
    inverse_of: :period_invoice_template
  accepts_nested_attributes_for :items, allow_destroy: true

  validates :name, :start_on, :items, presence: true
  validates_date :end_on,
    allow_blank: true,
    on_or_after: :start_on,
    on_or_after_message: :must_be_later_than_start_on,
    if: -> { start_on.present? }

  def to_s
    name
  end
end
