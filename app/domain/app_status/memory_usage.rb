# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus::MemoryUsage
  def initialize
    super

    @memory_usage_determinable = memory_usage_determinable?
    @memory_usage_limit_percentage = memory_usage_limit_percentage
    @memory_usage_exceeds_limit = memory_usage_exceeds_limit? if @memory_usage_determinable
  end

  def details
    details = {
      memory_usage_determinable: @memory_usage_determinable,
      memory_usage_limit_percentage: @memory_usage_limit_percentage
    }

    if @memory_usage_determinable
      details[:memory_usage_exceeds_limit] = @memory_usage_exceeds_limit
    end

    details
  end

  def code
    return AppStatus::SERVICE_UNAVAILABLE unless @memory_usage_determinable

    @memory_usage_exceeds_limit ? AppStatus::SERVICE_UNAVAILABLE : AppStatus::OK
  end

  private

  def memory_usage_determinable?
    File.exist?(memory_max_file) &&
      File.exist?(memory_current_file) &&
      File.exist?(memory_stat_file)
  end

  def memory_usage_limit_percentage
    Settings.app_status.memory_usage.limit_percentage
  end

  def memory_usage_exceeds_limit?
    max_memory = File.read(memory_max_file).strip

    # Defaults to max if no limit is set
    return false if max_memory == "max"

    max_memory = max_memory.to_i
    return true if max_memory.zero?

    current_memory_usage = File.read(memory_current_file).to_i
    inactive_memory = File.read(memory_stat_file).match(/^inactive_file (\d+)$/)[1].to_i

    # Approximate working set size
    current_memory_usage -= inactive_memory

    memory_usage_percentage = (current_memory_usage.to_f / max_memory) * 100
    memory_usage_percentage > @memory_usage_limit_percentage
  end

  def memory_max_file
    "/sys/fs/cgroup/memory.max"
  end

  def memory_current_file
    "/sys/fs/cgroup/memory.current"
  end

  def memory_stat_file
    "/sys/fs/cgroup/memory.stat"
  end
end
