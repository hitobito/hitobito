# frozen_string_literal: true

require 'test_helper'

class CommitReminderJobTest < ActiveJob::TestCase
  include Mocha::API

  setup do
    Employee.update_all(worktimes_commit_reminder: false)
    @employee = employees(:long_time_john) # Nutzt deine Fixtures
  end

  test 'perform sends mail on the last working day of the month (Happy Case)' do
    # 30. April 2025 ist ein Mittwoch (kein Feiertag)
    travel_to Date.new(2025, 4, 30) do
      setup_employee
      EmployeeMailer.expects(:worktime_commit_reminder_mail).with(@employee).returns(mock(deliver_now: true))
      CommitReminderJob.new.perform
    end
  end

  test 'perform sends mail on Friday if the month ends on a Sunday' do
    # 31. August 2025 ist ein Sonntag. Letzter Arbeitstag ist Freitag, der 29.
    travel_to Date.new(2025, 8, 29) do
      setup_employee
      EmployeeMailer.expects(:worktime_commit_reminder_mail).once.returns(mock(deliver_now: true))
      CommitReminderJob.new.perform
    end
    travel_to Date.new(2025, 8, 31) do
      setup_employee
      EmployeeMailer.expects(:worktime_commit_reminder_mail).never
      CommitReminderJob.new.perform
    end
  end

  test 'perform does not send mail if not last working day' do
    # 28. August 2025 ist ein Donnerstag und somit vorletzter Arbeitstag
    travel_to Date.new(2025, 8, 28) do
      setup_employee
      EmployeeMailer.expects(:worktime_commit_reminder_mail).never
      CommitReminderJob.new.perform
    end
  end

  test 'perform respects holidays' do
    # Feiertag am 31. Dezember 2025 (Mittwoch)
    Holiday.create!(holiday_date: Date.new(2025, 12, 31), musthours_day: 0)
    travel_to Date.new(2025, 12, 30) do
      setup_employee
      EmployeeMailer.expects(:worktime_commit_reminder_mail).once.returns(mock(deliver_now: true))
      CommitReminderJob.new.perform
    end
  end

  test 'perform does not send mail if employee already committed this month' do
    travel_to Date.new(2025, 4, 30) do
      setup_employee(committed_at: Time.zone.today.end_of_month)
      EmployeeMailer.expects(:worktime_commit_reminder_mail).never
      CommitReminderJob.new.perform
    end
  end

  test 'perform does not send mail if reminder is disabled' do
    travel_to Date.new(2025, 4, 30) do
      setup_employee(remind: false)
      EmployeeMailer.expects(:worktime_commit_reminder_mail).never
      CommitReminderJob.new.perform
    end
  end

  test 'perform does not send if no active employments' do
    travel_to Date.new(2025, 4, 30) do
      setup_employee
      @employee.employments.first.update!(end_date: Date.new(2025, 1, 1))
      EmployeeMailer.expects(:worktime_commit_reminder_mail).never
      CommitReminderJob.new.perform
    end
  end

  private

  def setup_employee(remind: true, committed_at: 1.month.ago)
    @employee.update!(worktimes_commit_reminder: remind, committed_worktimes_at: committed_at)
  end
end
