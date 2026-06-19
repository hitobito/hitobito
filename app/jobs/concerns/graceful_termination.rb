# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module GracefulTermination
  # use the check_terminated! method in a job to support graceful termination
  # at a defined point
  #
  # class Job < BaseJob
  #   include GracefulTermination
  #
  #   def perform
  #     many.times do
  #       check_terminated!
  #
  #       perform_work ...
  #     end
  #   end
  # end

  def should_terminate_with_signal!(signal)
    @signal = signal
  end

  private

  def check_terminated!
    raise SignalException.new(@signal) if @signal
  end
end
