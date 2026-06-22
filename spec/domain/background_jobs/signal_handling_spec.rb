#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe BackgroundJobs::SignalHandling do
  include DelayedJobSpecHelper

  let(:job) { double("TestJob") }
  let(:signals) { ["SIGINT", "SIGTERM"] }

  around do |example|
    old_signal_handlers = {}

    signals.each do |signal|
      old_signal_handlers[signal] = trap(signal) {}
    end

    example.run

    old_signal_handlers.each do |signal, old_handler|
      trap(signal, old_handler)
    end
  end

  it "should pass payload object to signal handler" do
    expect(described_class).to receive(:handle_termination_signals).with(
      instance_of(BaseJob), "INT", "TERM"
    ).and_call_original

    BaseJob.new.enqueue!
    expect(Delayed::Worker.new.work_off).to eql([1, 0])
  end

  it "should raise signal exception when job doesnt handle graceful termination" do
    expect(job.class).to receive(:include?).with(GracefulTermination).and_return(false)

    described_class.handle_termination_signals(job, *signals) do
      signals.each do |signal|
        registered_handler = trap(signal) {}

        expect(registered_handler).to respond_to(:call)
        expect(job).not_to receive(:should_terminate_with_signal!)
        expect { registered_handler.call }.to raise_error(SignalException, signal)
      end
    end
  end

  it "should tell job to terminate gracefully when job handles graceful termination" do
    expect(job.class).to receive(:include?).with(GracefulTermination).and_return(true)

    described_class.handle_termination_signals(job, *signals) do
      signals.each do |signal|
        registered_handler = trap(signal) {}

        expect(registered_handler).to respond_to(:call)
        expect(job).to receive(:should_terminate_with_signal!).with(signal)
        expect { registered_handler.call }.not_to raise_error
      end
    end
  end

  it "should call old handlers before raising signal exception" do
    expect(job.class).to receive(:include?).with(GracefulTermination).and_return(false)

    signals.each do |signal|
      trap(signal) { job.old_handler_method }
    end

    described_class.handle_termination_signals(job, *signals) do
      signals.each do |signal|
        registered_handler = trap(signal) {}

        expect(registered_handler).to respond_to(:call)
        expect(job).to receive(:old_handler_method)
        expect { registered_handler.call }.to raise_error(SignalException, signal)
      end
    end
  end

  it "should restore old handlers" do
    expect(job.class).to receive(:include?).with(GracefulTermination).and_return(false)

    signals.each do |signal|
      trap(signal) { job.restored_handler_method }
    end

    described_class.handle_termination_signals(job, *signals) {}

    signals.each do |signal|
      registered_handler = trap(signal) {}

      expect(registered_handler).to respond_to(:call)
      expect(job).to receive(:restored_handler_method)
      expect { registered_handler.call }.not_to raise_error
    end
  end
end
