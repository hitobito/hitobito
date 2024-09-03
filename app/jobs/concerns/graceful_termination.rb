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
  #     handle_termination_signals do
  #        many.times do
  #           check_terminated!
  #
  #           perform_work ...
  #        end
  #     end
  #   end
  #

  private

  def handle_termination_signals
    handle_termination_signal("INT") do
      handle_termination_signal("TERM") do
        yield
      end
    end
  end

  def handle_termination_signal(signal)
    @signal = nil
    old_handler = trap(signal) do
      @signal = signal
      old_handler.call
    end
    yield
  ensure
    trap(signal, old_handler)
  end

  def check_terminated!
    raise SignalException.new(@signal) if @signal
  end
end
