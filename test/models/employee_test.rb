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

require 'test_helper'

class EmployeeTest < ActiveSupport::TestCase
  def setup
    years = 1990..2006
    setup_regular_holidays(years.to_a)
  end

  def test_half_year_employment
    employee = Employee.find(1)
    period = year_period(employee)

    assert_equal 1, employee.statistics.employments_during(period).size
    assert_in_delta 12.60, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_in_delta 12.60, employee.statistics.total_vacations(period), 0.005
    assert_equal(-127 * 8, employee.statistics.overtime(period))
  end

  def test_various_employment
    employee = Employee.find(2)
    period = year_period(employee)
    employments = employee.statistics.employments_during(period)

    assert_equal 3, employments.size
    assert_equal employments[0].start_date, Date.new(2005, 11, 1)
    assert_equal employments[0].end_date, Date.new(2006, 1, 31)
    assert_equal 92, employments[0].period.length
    assert_in_delta 2.52, employments[0].vacations, 0.005
    assert_in_delta 3.73, employments[1].vacations, 0.005
    assert_in_delta 7.33, employments[2].vacations, 0.005
    assert_in_delta 13.58, employee.statistics.remaining_vacations(period.end_date), 0.01
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_in_delta 13.58, employee.statistics.total_vacations(period), 0.01
    assert_in_delta 11.90, employee.statistics.total_vacations(Period.year_for(Date.new(2006))), 0.01
    assert_equal employee.statistics.overtime(period), - ((64 * 0.4 * 8) + (162 * 0.2 * 8) + (73 * 8))
  end

  def test_next_year_employment
    employee = Employee.find(3)
    period = year_period(employee)

    assert_equal 0, employee.statistics.employments_during(period).size
    assert_equal 0, employee.statistics.remaining_vacations(Date.new(2006, 12, 31))
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_equal 0, employee.statistics.total_vacations(period)
    assert_equal 0, employee.statistics.overtime(period)
  end

  def test_left_this_year_employment
    employee = Employee.find(4)
    period = year_period(employee)

    assert_equal 1, employee.statistics.employments_during(period).size
    assert_in_delta 29.92, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_in_delta 29.92, employee.statistics.total_vacations(period), 0.005
    assert_in_delta(- 387 * 8 * 0.8, employee.statistics.overtime(period), 0.005)
  end

  def test_long_time_employment
    employee = Employee.find(5)
    period = year_period(employee)

    assert_equal 1, employee.statistics.employments_during(period).size
    assert_in_delta 382.5, employee.statistics.remaining_vacations(period.end_date), 0.005
    assert_equal 0, employee.statistics.used_vacations(period)
    assert_in_delta 382.5, employee.statistics.total_vacations(period), 0.005
    assert_equal(-31_500, employee.statistics.overtime(period))
  end

  def test_alltime_leaf_work_items
    e = employees(:pascal)

    assert_equal work_items(:allgemein, :puzzletime, :webauftritt), e.alltime_leaf_work_items
  end

  def test_alltime_main_work_items
    e = employees(:pascal)

    assert_equal work_items(:puzzle, :swisstopo), e.alltime_main_work_items
  end

  test 'includes only those employees with billable worktimes in given period' do
    order = orders(:webauftritt)
    from = '01.12.2006'
    to = '11.12.2006'

    empls = Employee.with_worktimes_in_period(order, from, to)

    assert 1, empls.size
    assert_includes empls, employees(:mark)
  end

  test 'includes all employees with billable worktimes for given order if no period specified' do
    order = orders(:webauftritt)
    from = nil
    to = nil

    empls = Employee.with_worktimes_in_period(order, from, to)

    assert_equal 2, empls.size
    assert_includes empls, employees(:mark)
    assert_includes empls, employees(:lucien)
  end

  test '#current scope' do
    refute_equal Employee.count, Employee.current.count
    assert_arrays_match employees(:long_time_john, :various_pedro, :next_year_pablo), Employee.current
  end

  test '#pending_worktimes_commit scope' do
    this_month = Time.zone.today.end_of_month
    last_month = 1.month.ago.end_of_month

    Employee.update_all(committed_worktimes_at: nil)

    assert_predicate Employee.pending_worktimes_commit, :present?

    Employee.update_all(committed_worktimes_at: this_month)

    assert_predicate Employee.pending_worktimes_commit, :blank?

    Employee.update_all(committed_worktimes_at: last_month)

    assert_predicate Employee.pending_worktimes_commit, :present?
  end

  test '#management scope' do
    management_employees = Employee.management

    assert management_employees.all?(&:management)
  end

  private

  def year_period(employee)
    employee.statistics.send :employment_period_to, Date.new(2006, 12, 31)
  end
end
