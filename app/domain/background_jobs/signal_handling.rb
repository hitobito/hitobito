#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module BackgroundJobs
  # This delayed plugin registeres signal handlers for termination signals so the
  # delayed job worker can react to them. By default the delayed job worker would wait
  # with exiting until the currently running job is finished. This is undesirable,
  # as after a grace period, if the worker isn't done yet, a SIGKILL is issued which
  # we can't react to, thus delayed job hooks are not run and the attempt number of
  # the job is not increased. On jobs which lead to an out of memory in every attempt
  # this would lead to workers being blocked indefinitely.
  #
  # Delayed job has a setting to handle termination signals but it doesn't allow us to
  # customize the behavior when reacting to a signal so we implemented it ourselfes
  # to match our needs. Additionally this setting would lead to a signal exception being
  # raised even when the worker isn't currently running any job. Our logic only raises
  # during a job execution.

  class SignalHandling < Delayed::Plugin
    callbacks do |lifecycle|
      lifecycle.around(:perform) do |_, delayed_job, &block|
        handle_termination_signals(delayed_job.payload_object, "INT", "TERM") do
          block.call
        end
      end
    end

    def self.handle_termination_signals(job, *signals)
      old_signal_handlers = {}

      job_terminates_gracefully = job.class.include?(GracefulTermination)

      signals.each do |signal|
        old_handler = handle_termination_signal(signal, job, job_terminates_gracefully)

        old_signal_handlers[signal] = old_handler
      end

      yield
    ensure
      restore_old_signal_handlers(old_signal_handlers)
    end

    # This signal handler does one of two things:
    #
    # 1. If the job is not gracefully terminatable (i.e. the job class doesnt include the
    #    GracefulTermination module), a signal exception is raised immediatly, causing the
    #    current job execution attempt to fail and thus leading to the execution of the
    #    delayed job hooks.
    # 2. If the job is gracefully terminatable (i.e. the job class includes the graceful
    #    termination module), the job is informed that it should terminate. The next time
    #    the job checks if it should terminate, a signal exception is raised.
    #
    # Additionally the previously registered handler is called if it is callable.
    def self.handle_termination_signal(signal, job, job_terminates_gracefully)
      old_handler = trap(signal) do
        old_handler.call if old_handler.respond_to?(:call)

        if job_terminates_gracefully
          job.should_terminate_with_signal!(signal)
        else
          raise SignalException.new(signal)
        end
      end
    end

    # After the job is run the old signal handlers are restored to the previous ones, so our
    # handler logic is only executed while a job is running.
    def self.restore_old_signal_handlers(old_signal_handlers)
      old_signal_handlers.each do |signal, old_handler|
        trap(signal, old_handler)
      end
    end
  end
end
