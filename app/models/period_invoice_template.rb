#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplate < ActiveRecord::Base
  belongs_to :group

  has_many :invoice_runs, dependent: :nullify
  belongs_to :recipient_source, polymorphic: true, validate: true

  has_many :items, dependent: :destroy, class_name: "PeriodInvoiceTemplate::Item",
    inverse_of: :period_invoice_template
  accepts_nested_attributes_for :items, allow_destroy: true

  validates :name, :start_on, :items, presence: true
  validates_date :end_on,
    allow_blank: true,
    on_or_after: :start_on,
    on_or_after_message: :must_be_later_than_start_on,
    if: -> { start_on.present? }
  validates :recipient_group_type, presence: true, inclusion: {in: ->(entry) {
    entry.group.class.child_types.map(&:name)
  }}
  validate :assert_changes_to_recipient_group_allowed

  after_save :save_recipient_source

  def to_s
    name
  end

  private

  def assert_changes_to_recipient_group_allowed
    if recipient_group_type_changed? && invoice_runs.any?
      errors.add(:recipient_group_type, :readonly_due_to_existing_invoice_runs)
    end
  end

  def save_recipient_source
    recipient_source&.save
  end
end
