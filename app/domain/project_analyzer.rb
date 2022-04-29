# frozen_string_literal: true

# Copyright (c) 2022-2022, Digisus Lab. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class ProjectAnalyzer
  SEPARATOR = /[-_]/.freeze

  attr_reader :project, :stage

  def initialize(name = nil)
    raise ArgumentError, 'Please pass a project-name or a database-name to this class' unless name

    @project, stage_hint = splitter(name)
    @stage = determine_stage(stage_hint)
  end

  def to_s
    "<ProjectAnayzer -- Project: '#{@project}' - Stage: '#{@stage}'>"
  end

  private

  def determine_stage(stage)
    case stage
    when /^int/i  then 'integration'
    when /^prod/i then 'production'
    when /^sta/i  then 'staging'
    when /^dev/i  then 'development'
    else stage
    end
  end

  def splitter(name)
    parts = name.split(SEPARATOR)
    separator_char = name.scan(SEPARATOR).first

    case parts.count
    when 2   then parts
    when 3.. then [parts[1..-2].join(separator_char), parts.last]
    end
  end
end
