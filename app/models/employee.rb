# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.
# == Schema Information
#
# Table name: employees
#
#  id                        :integer          not null, primary key
#  firstname                 :string(255)      not null
#  lastname                  :string(255)      not null
#  shortname                 :string(3)        not null
#  email                     :string(255)      not null
#  management                :boolean          default(FALSE)
#  initial_vacation_days     :float
#  ldapname                  :string(255)
#  eval_periods              :string(3)        is an Array
#  department_id             :integer
#  committed_worktimes_at    :date
#  probation_period_end_date :date
#  phone_office              :string
#  phone_private             :string
#  street                    :string
#  postal_code               :string
#  city                      :string
#  birthday                  :date
#  emergency_contact_name    :string
#  emergency_contact_phone   :string
#  marital_status            :integer
#  social_insurance          :string
#  crm_key                   :string
#  additional_information    :text
#  reviewed_worktimes_at     :date
#  nationalities             :string           is an Array
#  graduation                :string
#  identity_card_type        :string
#  identity_card_valid_until :date
#  encrypted_password        :string           default("")
#  remember_created_at       :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  workplace_id              :bigint
#  worktimes_commit_reminder :boolean          default(TRUE), not null
#  member_coach_id           :integer
#

class Employee < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :rememberable,
         :omniauthable
  # :validatable,
  # :confirmable,
  # :registerable,
  # :recoverable,

  INTERNAL_ATTRS = %w[id eval_periods encrypted_password updated_at created_at].freeze

  include Evaluatable
  include ReportType::Accessors
  extend Conditioner

  has_paper_trail(meta: { employee_id: proc(&:id) }, skip: Employee::INTERNAL_ATTRS)

  enum :marital_status, %w[
    single
    married
    widowed
    civil_partnership
    divorced
  ].freeze

  # All dependencies between the models are listed below.
  belongs_to :department, optional: true
  belongs_to :workplace, optional: true
  belongs_to :member_coach, optional: true, class_name: 'Employee'

  has_and_belongs_to_many :invoices

  has_many :employments, dependent: :destroy
  has_one :current_employment, -> { during(Period.current_day) }, class_name: 'Employment'

  has_many :worktimes
  has_many :absences,
           -> { order('name').distinct },
           through: :worktimes
  has_many :overtime_vacations, dependent: :destroy
  has_many :managed_orders, class_name: 'Order', foreign_key: :responsible_id, dependent: :nullify
  has_many :order_team_members, dependent: :destroy
  has_many :custom_lists, dependent: :destroy
  has_many :plannings, dependent: :destroy
  has_one :running_time,
          -> { where(report_type: ReportType::AutoStartType::INSTANCE.key) },
          class_name: 'Ordertime'
  has_many :expenses, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_many :members, class_name: 'Employee', foreign_key: :member_coach_id,
                     dependent: :destroy, inverse_of: :member_coach

  before_validation do
    nationalities.try(:reject!, &:blank?)
  end

  # Validation helpers.
  validates_by_schema except: :eval_periods
  validates :shortname, uniqueness: { case_sensitive: false }
  validates :ldapname, uniqueness: { allow_blank: true, case_sensitive: false }
  validate :periods_format

  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'

  scope :list, -> { order(lastname: :asc, firstname: :asc) }
  scope :current, -> { joins(:employments).merge(Employment.during(Period.current_day)) }
  scope :management, -> { where(management: true) }

  # logic should match CompletableHelper#recently_completed
  scope :pending_worktimes_commit, lambda {
                                     where('committed_worktimes_at < ? OR committed_worktimes_at IS NULL', Time.zone.today.end_of_month)
                                   }
  scope :active_employed_current_month, -> { joins(:employments).merge(Employment.active.during(Period.current_month)) }

  attr_accessor :remaining_vacations, :sort_col # used for multiabsence and not persisted

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :rememberable,
         :omniauthable,
         :registerable,
         omniauth_providers: %i[keycloakopenid saml]
  # :validatable,
  # :confirmable,
  # :recoverable,

  def apply_omniauth(omni)
    authentications.build(
      provider: omni['provider'],
      uid: omni['uid'],
      token: omni['credentials'].token,
      token_secret: omni['credentials'].token_secret
    )
  end

  def password_required?
    # authentications.empty? && super
    false
  end

  def providers
    authentications.pluck(:provider)
  end

  class << self
    def employed_ones(period, sort = true)
      result = joins('left join employments em on em.employee_id = employees.id')
               .where('(em.end_date IS null or em.end_date >= ?) AND em.start_date <= ?',
                      period.start_date, period.end_date)
               .distinct
      sort ? result.list : result
    end

    def worktimes
      Worktime.all
    end

    def encode(pwd)
      Digest::SHA1.hexdigest(pwd)
    end

    def with_worktimes_in_period(order, from, to)
      e_ids = order.worktimes
                   .in_period(Period.new(from, to))
                   .billable
                   .select(:employee_id)
      Employee.where(id: e_ids)
    end
  end

  ##### helper methods #####

  def to_s
    "#{lastname} #{firstname}"
  end

  def order_responsible?
    @order_responsible ||= managed_orders.exists?
  end

  # Accessor for the initial vacation days. Default is 0.
  def initial_vacation_days
    super || 0
  end

  def eval_periods
    super || []
  end

  # main work items this employee ever worked on
  def alltime_main_work_items
    WorkItem.select('DISTINCT work_items.*')
            .joins('RIGHT JOIN work_items leaves ON leaves.path_ids[1] = work_items.id')
            .joins('RIGHT JOIN worktimes ON worktimes.work_item_id = leaves.id')
            .where(worktimes: { employee_id: id })
            .where.not(work_items: { id: nil })
            .list
  end

  def alltime_leaf_work_items
    WorkItem.select('DISTINCT work_items.*')
            .joins('RIGHT JOIN worktimes ON worktimes.work_item_id = work_items.id')
            .where(worktimes: { employee_id: id })
            .where.not(work_items: { id: nil })
            .list
  end

  def statistics
    @statistics ||= EmployeeStatistics.new(self)
  end

  def committed_date?(date)
    committed_worktimes_at && date <= committed_worktimes_at
  end

  def committed_period?(period)
    committed_date?(period.end_date)
  end

  def reviewed_date?(date)
    reviewed_worktimes_at && date <= reviewed_worktimes_at
  end

  def reviewed_period?(period)
    reviewed_date?(period.end_date)
  end

  ######### employment information ######################

  # Returns the current employement percent value.
  # Returns nil if no current employement is present.
  def current_percent
    percent(Time.zone.today)
  end

  # Returns the employment percent value for a given employment date
  def percent(date)
    empl = employment_at(date)
    empl&.percent
  end

  # Returns the employement at the given date, nil if none is present.
  def employment_at(date)
    date = Date.parse(date) if date.is_a? String
    employments.find_by('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', date, date)
  end

  def as_json(_options)
    h = {}
    h[:id] = id
    h[:firstname] = firstname
    h[:lastname] = lastname
    h
  end

  private

  def periods_format
    validate_periods_format(:eval_periods, eval_periods)
  end

  def validate_periods_format(attr, periods)
    periods.each do |p|
      errors.add(attr, 'ist nicht gültig') unless /^-?\d[dwmqy]?$/.match?(p)
    end
  end
end
