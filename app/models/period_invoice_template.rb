#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplate < ActiveRecord::Base
  belongs_to :group

  has_many :invoice_runs, dependent: :nullify
  belongs_to :recipient_source, polymorphic: true, validate: true, autosave: true

  has_many :items, dependent: :destroy, class_name: "PeriodInvoiceTemplate::Item",
    inverse_of: :period_invoice_template
  accepts_nested_attributes_for :recipient_source
  accepts_nested_attributes_for :items, allow_destroy: true

  validates :name, :start_on, :items, presence: true
  validates_date :end_on,
    allow_blank: true,
    on_or_after: :start_on,
    on_or_after_message: :must_be_later_than_start_on,
    if: -> { start_on.present? }
  validate :assert_valid_recipient_source
  validate :assert_changes_to_recipient_source_allowed

  def to_s
    name
  end

  def build_recipient_source(params)
    unless InvoiceRun::RECIPIENT_TYPES.include?(params[:type])
      errors.add("recipient_source.type")
      return
    end
    type = params.delete(:type).constantize
    self.recipient_source ||= type.new(params)
    self.recipient_source.attributes = params
  end

  def recipient_group_type
    return recipient_source.group_type.safe_constantize if recipient_source.is_a?(GroupsFilter)
    group.class
  end

  private

  def assert_valid_recipient_source
    if recipient_source.instance_of?(::GroupsFilter)
      unless group.class.child_types.map(&:name).include?(recipient_source.group_type)
        recipient_source.errors.add(:group_type)
        errors.add(:recipient_source)
      end
    end
  end

  def assert_changes_to_recipient_source_allowed
    if recipient_source.changes_to_save.present? && invoice_runs.any?
      errors.add(:recipient_source, :readonly_due_to_existing_invoice_runs)
    end
  end
end
