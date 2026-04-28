# frozen_string_literal: true

#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class CommitReminderJob < CronJob
  self.cron_expression = '0 5 * * *'

  def perform
    return unless last_working_day_of_month?

    employees =
      Employee
      .active_employed_current_month
      .pending_worktimes_commit
      .where(worktimes_commit_reminder: true)

    send_mails_to(employees)
  end

  private

  def send_mails_to(employees)
    employees.find_each do |employee|
      EmployeeMailer
        .worktime_commit_reminder_mail(employee)
        .deliver_now
    end
  end

  def last_working_day_of_month?
    target_day = Date.current.end_of_month
    target_day = target_day.prev_day while Holiday.non_working_day?(target_day)
    Date.current == target_day
  end
end
