#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AppStatus::MemoryUsage do
  subject { described_class.new }

  describe "memory usage determinable" do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:read).and_call_original

      stub_file_read("/sys/fs/cgroup/memory.max", max_memory)
      stub_file_read("/sys/fs/cgroup/memory.current", current_memory_usage)
      stub_file_read("/sys/fs/cgroup/memory.stat", "inactive_file #{inactive_file_memory}")
    end

    context "no memory usage hard limit" do
      let(:max_memory) { "max" }
      let(:current_memory_usage) { "2000000" }
      let(:inactive_file_memory) { "100000" }

      it "should have healthy status" do
        expect(subject.code).to eql(:ok)
        expect(subject.details).to eql(
          memory_usage_determinable: true,
          memory_usage_exceeds_limit: false,
          memory_usage_limit_percentage: 95
        )
      end
    end

    context "memory usage limit not reached" do
      let(:max_memory) { "2000000" }
      let(:current_memory_usage) { "2000000" }
      let(:inactive_file_memory) { "100000" }

      it "should have healthy status" do
        expect(subject.code).to eql(:ok)
        expect(subject.details).to eql(
          memory_usage_determinable: true,
          memory_usage_exceeds_limit: false,
          memory_usage_limit_percentage: 95
        )
      end
    end

    context "memory usage limit reached" do
      let(:max_memory) { "2000000" }
      let(:current_memory_usage) { "2000000" }
      let(:inactive_file_memory) { "5000" }

      it "should have unhealthy status" do
        expect(subject.code).to eql(:service_unavailable)
        expect(subject.details).to eql(
          memory_usage_determinable: true,
          memory_usage_exceeds_limit: true,
          memory_usage_limit_percentage: 95
        )
      end
    end

    context "custom memory usage limit percentage" do
      let(:max_memory) { "2000000" }
      let(:current_memory_usage) { "1800000" }
      let(:inactive_file_memory) { "100000" }

      it "should have healthy status when not reached" do
        allow(Settings.app_status.memory_usage).to receive(:limit_percentage).and_return(90)

        expect(subject.code).to eql(:ok)
        expect(subject.details).to eql(
          memory_usage_determinable: true,
          memory_usage_exceeds_limit: false,
          memory_usage_limit_percentage: 90
        )
      end

      it "should have unhealthy status when reached" do
        allow(Settings.app_status.memory_usage).to receive(:limit_percentage).and_return(80)

        expect(subject.code).to eql(:service_unavailable)
        expect(subject.details).to eql(
          memory_usage_determinable: true,
          memory_usage_exceeds_limit: true,
          memory_usage_limit_percentage: 80
        )
      end
    end

    def stub_file_read(file, content)
      allow(File).to receive(:exist?).with(file).and_return(true)
      allow(File).to receive(:read).with(file).and_return(content)
    end
  end

  describe "memory usage not determinable" do
    it "should report memory usage as undeterminable if one of the memory files does not exist" do
      [
        "/sys/fs/cgroup/memory.max", "/sys/fs/cgroup/memory.current", "/sys/fs/cgroup/memory.stat"
      ].each do |memory_file|
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:exist?).with(memory_file).and_return(false)

        expect(subject.code).to eql(:service_unavailable)
        expect(subject.details).to eql(
          memory_usage_determinable: false,
          memory_usage_limit_percentage: 95
        )
      end
    end
  end
end
