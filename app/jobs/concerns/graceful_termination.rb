# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module GracefulTermination
  # use this method with a job to support graceful termination via an early
  # return in case `@terminate` is true
  #
  # def perform
  #   handle_termination_signals do
  #      many.times do
  #         return if @terminate
  #
  #         perform_work ...
  #      end
  #   end
  # end
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
    @terminate = false
    old_handler = trap(signal) do
      @terminate = true
      old_handler.call
    end
    yield
  ensure
    trap(signal, old_handler)
  end

  def check_terminated
    raise SignalException if @terminate
  end
end
