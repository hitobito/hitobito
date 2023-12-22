# frozen_string_literal: true

#  Copyright (c) 2023-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'date'

# This is used by bin/version and integrated into it
# with `rake bin/version`
class ReleaseVersion
  def current_version(stage = :production)
    `#{tag_lookup_cmd(stage)} | head -n 1`.chomp
  end

  def next_integration_version
    prod = current_version(:production)

    day_counter = days_since(prod)
    new_int = "#{prod}-#{day_counter}"

    if all_versions(:integration).include?(new_int)
      "#{new_int}-#{current_sha}"
    else
      new_int
    end
  end

  def next_version(style = :patch, version = nil)
    incrementor = \
      case style.to_sym
      when :patch, :regular then method(:"next_#{style}_version")
      when :custom then ->(_parts) { version.split('.').to_a }
      end

    current_version(:production)
      .split('.')
      .then { |parts| incrementor[parts] }
      .join('.')
  end

  def all_versions(stage = :production)
    `#{tag_lookup_cmd(stage)}`.chomp.split
  end

  def remote_version(stage, repo)
    cmd = [
      remote_lookup_cmd(repo),
      version_grep_cmd(stage),
      'sort -Vr',
      'head -n 1'
    ].join(' | ')

    `#{cmd}`
  end

  def days_since(version)
    tag_date = `git log #{version} -1 --format="%ct"`.chomp
    (Time.now.utc.to_date - Time.at(tag_date.to_i).to_date).to_i # rubocop:disable Rails/TimeZone
  end

  private

  def next_patch_version(parts)
    parts[0..1] + [parts[2].succ]
  end

  def next_regular_version(parts)
    if parts[2] != '0' || days_since(parts.join('.')) > 7
      [parts[0], parts[1].succ, '0']
    else
      parts
    end
  end

  def current_sha
    `git rev-parse --short HEAD`
  end

  def tag_lookup_cmd(stage)
    "git tag --sort=-committerdate --list | #{version_grep_cmd(stage)}"
  end

  def remote_lookup_cmd(repo)
    "git ls-remote --tags #{repo} | cut -f2 | sed 's!refs/tags/!!'"
  end

  def version_grep_cmd(stage)
    pattern =
      case stage
      when :production then [version_grep_pattern(stage)]
      when :integration then [version_grep_pattern(stage), version_grep_pattern(:production)]
      end

    "grep -E '(#{pattern.join('|')})'"
  end

  def version_grep_pattern(stage)
    case stage
    when :production  then '^[0-9][0-9.]+$' # 1.30.6
    when :integration then '^[0-9][0-9.]+-[0-9]+.*$' # 1.30.6-26 or 1.30.6-123-33b8937
    end
  end
end
