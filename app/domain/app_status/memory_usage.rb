# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus::MemoryUsage < AppStatus
  def initialize
    super()

    @memory_usage_limit_percentage = memory_usage_limit_percentage
    @memory_usage_exceeds_limit = memory_usage_exceeds_limit?
  end

  def details
    {
      memory_usage_exceeds_limit: @memory_usage_exceeds_limit,
      memory_usage_limit_percentage: @memory_usage_limit_percentage
    }
  end

  def code
    @memory_usage_exceeds_limit ? :service_unavailable : :ok
  end

  private

  def memory_usage_limit_percentage
    ENV.fetch("MEMORY_USAGE_LIMIT_PERCENTAGE", 95)
  end

  def memory_usage_exceeds_limit?
    max_memory = File.read("/sys/fs/cgroup/memory.max").strip

    # Defaults to max if no limit is set
    return false if max_memory == "max"

    max_memory = max_memory.to_f
    return true if max_memory.zero?

    current_memory_usage = File.read("/sys/fs/cgroup/memory.current").to_f
    inactive_memory = (File.read("/sys/fs/cgroup/memory.stat") =~ /^inactive_file (\d+)$/)
    current_memory_usage -= inactive_memory.to_f

    memory_usage_percentage = current_memory_usage / max_memory

    memory_usage_percentage > @memory_usage_limit_percentage
  end
end
