#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplate < ActiveRecord::Base
  belongs_to :group

  has_many :invoice_runs, dependent: :nullify

  validates :name, :start_on, presence: true
  validates_date :end_on,
    allow_blank: true,
    on_or_after: :start_on,
    on_or_after_message: :must_be_later_than_start_on,
    if: -> { start_on.present? }

  def to_s
    name
  end
end
