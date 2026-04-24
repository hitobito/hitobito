# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Abstract base class for dynamic invoice items which calculate their cost
# by counting some models within an invoice period and multiplying this count
# with a unit cost.
# Such items can be used in invoices addressed to groups or to people, or with a list
# or scope of groups or people, and are expected to calculate the price as follows:
# 1. When addressed to a single group: The item calculates the count of models related
#    to that specific recipient group. This is e.g. used for aggregated membership fees
#    which the recipient group has to pay to the root group.
# 2. When addressed to a single person: The item calculates the count of models related
#    to that specific recipient person. This is e.g. used when sending membership
#    invoices to the individual members of a group.
# 3. With a list of groups or a list of people: The item calculates the sum of counts
#    for each of these individual recipients. This is used for previewing the total
#    amount on an invoice form.
#
# In cases 1 and 2, a period item can also calculate a list of subjects (models) which
# contribute to the count. This is used to persist which subjects have already been
# taken into account (processed) in past invoices. Case 3 is only used for previewing
# counts, so the result of the #subjects method is undefined in that case.
#
# In all cases, a period item takes a period start date and an optional period end date,
# and only counts models which were "alive" or "active" some time during that period.
class Invoice::PeriodItem < InvoiceItem
  self.dynamic = true

  # Prepare the item for calculating preview counts for a list of recipient groups.
  # See case 3 in the documentation comment on this class.
  def self.for_groups(groups, **params)
    new(**params).tap do |item|
      item.groups = groups
      item.recipient_type = Group.sti_name
    end
  end

  # Prepare the item for calculating preview counts for a list of recipient people.
  # See case 3 in the documentation comment on this class.
  def self.for_people(people, **params)
    new(**params).tap do |item|
      item.people = people
      item.recipient_type = Person.sti_name
    end
  end

  attribute :count, :integer, default: nil
  attr_writer :groups, :people, :recipient_type

  # Forbid saving instances of this abstract class in the DB.
  # AR cannot handle abstract_class in the middle of an STI hierarchy, so we leave it at this.
  validates :type, exclusion: {in: %w[Invoice::PeriodItem]}

  validates :period_start_on, presence: true
  validates :name, :unit_cost, presence: true
  validates :unit_cost, money: true, unless: proc { |i| i.unit_cost.nil? }

  before_validation :enforce_unit_cost_precision

  def cost = dynamic_cost

  def dynamic_cost = unit_cost * count

  def unit_cost
    return nil if dynamic_cost_parameters[:unit_cost].nil?
    BigDecimal(dynamic_cost_parameters[:unit_cost])
  rescue ArgumentError, TypeError
    errors.add(:unit_cost, :is_not_a_decimal_number)
    nil
  end

  def count
    self[:count] ||= scope.count
  end

  # If used with a single recipient (cases 1 or 2 in the documentation comment on this
  # class), this method calculates a list of all models which are counted towards the
  # count of this invoice item. This list can be persisted in InvoiceRun::ProcessedSubjects
  # in order to exclude these subjects from later invoice runs with the same template item.
  def subjects
    @subjects ||= scope.map do |subject|
      {
        subject_id: subject.id,
        subject_type: subject_type.sti_name,
        template_item_id: template_item_id,
        item_id: id
      }
    end
  end

  def period_start_on
    dynamic_cost_parameters[:period_start_on]
  end

  def period_end_on
    dynamic_cost_parameters[:period_end_on] || Time.zone.today
  end

  def template_item_id
    dynamic_cost_parameters[:template_item_id]
  end

  def recalculate
    self[:count] = nil
    @subjects = nil
    super
  end

  private

  def scope
    # This is only a sample implementation. Subclasses may as well
    # redefine this method entirely.
    base_scope # Consider models...
      .merge(group_condition) # ... which belong to relevant groups...
      .merge(people_condition) # ... which belong to relevant people...
      .merge(not_processed_before_condition) # ... which haven't been processed in other invoices...
      .merge(active_condition(period_start_on, period_end_on)) # ... which were active in the period
  end

  def base_scope
    raise "implement in subclass"
  end

  # Subjects are models which are counted when calculating the total cost of the invoice item.
  # For membership invoices, the subjects are usually people or roles.
  def subject_type
    raise "implement in subclass"
  end

  def active_condition(start_on, end_on)
    raise "implement in subclass"
  end

  # The recipient is the model which receives and pays the invoice.
  # For membership invoices, the recipients are usually groups or people.
  def recipient_type
    @recipient_type ||= invoice&.recipient_type
  end

  def group_condition
    # This joins the "ancestor" group to the query. In the case of group invoices (case 1 in
    # the documentation comment on this class), the ancestor is the recipient of the invoice.
    # In the case of invoices addressed to individual people (case 2), the ancestor is just
    # the invoice sender group. In case 3, when calculating the preview counts for a whole
    # list of recipient groups, each of these recipient groups is a separate ancestor.
    # Typically, for each ancestor group, ultimately a separate invoice will be generated.
    #
    # Example: The root group sends membership invoices to all its Vereine, counting specific
    # membership roles in subgroups of these Vereine. Then, each Verein is an ancestor, joined
    # onto the groups of the membership roles. So during the preview count calculation of the
    # whole invoice run (case 3), there are multiple ancestors present at the same time, while
    # in the final invoices (case 1), only one ancestor per invoice is present.
    #
    # Therefore, all calculations in period items are done per ancestor group / in the context
    # of each ancestor group. Any DISTINCT statements in the business logic for deduplicating
    # subjects should keep rows with separate ancestor.id separate. E.g. if a period item
    # should only count each person once, what we actually mean is it should count each person
    # once per ancestor group: select("people.id", "ancestor.id AS ancestor_id").distinct
    #
    # The above would also hold true already for the #groups of a period item. However, the
    # ancestor groups are the mechanism used to implement deep search efficiently. If only
    # layer-local search or local search is required, this method can be overridden accordingly.
    #
    # Assumes the base_scope is already joined to the :group which the subjects belong to.
    Group.joins(
      "INNER JOIN groups ancestor ON ancestor.lft <= groups.lft AND ancestor.rgt > groups.lft"
    ).where(ancestor: {id: groups})
  end

  def people_condition
    # Assumes the base_scope is already joined to the :person which the subjects belong to.
    Person.where(id: people)
  end

  def not_processed_before_condition
    subject_type.where.not(existing_processed_subjects.arel.exists)
  end

  def existing_processed_subjects
    InvoiceRun::ProcessedSubject
      .where(processed_subjects_table[:subject_id].eq(subjects_table[:id]))
      .where(subject_type: subject_type.sti_name)
      .where(template_item_id: template_item_id)
      .merge(with_previous_invoice_to_same_recipient)
  end

  def with_previous_invoice_to_same_recipient
    table_name = InvoiceRun::ProcessedSubject.quoted_table_name

    InvoiceRun::ProcessedSubject
      .joins("INNER JOIN invoice_items prev_items ON #{table_name}.item_id = prev_items.id")
      .joins("INNER JOIN invoices previous_invoice ON prev_items.invoice_id = previous_invoice.id")
      .where(Arel.sql("previous_invoice.recipient_id").eq(recipient_id_expression))
      .where(previous_invoice: {recipient_type: recipient_type})
      .where.not(previous_invoice: {id: invoice&.id})
  end

  def groups
    # If no specific groups are given, fall back to the invoice recipient or invoice layer
    @groups ||= invoice&.recipient&.is_a?(Group) ? invoice.recipient_id : invoice&.group_id
  end

  def people
    # If no specific people are given, fall back to the invoice recipient or no people condition
    @people ||= invoice&.recipient&.is_a?(Person) ? invoice.recipient_id : Person.all
  end

  def enforce_unit_cost_precision
    dynamic_cost_parameters[:unit_cost] = ActiveSupport::NumberHelper.number_to_currency(
      dynamic_cost_parameters[:unit_cost], format: "%n", delimiter: ""
    )
  end

  def processed_subjects_table = InvoiceRun::ProcessedSubject.arel_table

  def subjects_table = subject_type.arel_table

  def recipient_id_expression
    return Arel.sql("ancestor.id") if recipient_type == "Group"

    recipient_type.constantize.arel_table[:id]
  end
end
