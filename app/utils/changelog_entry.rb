# frozen_string_literal: true

#  Copyright (c) 2022, Stiftung für junge Auslandschweizer. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangelogEntry
  GITHUB_BASE_URL = 'https://github.com/hitobito/'
  GITHUB_CORE_ISSUE_BASE_URL = GITHUB_BASE_URL + 'hitobito/issues/'

  CORE_ISSUE_HASH_REGEX = /(\(#(\d*)\)).?$/
  WAGON_ISSUE_HASH_REGEX = /(\((hitobito_\w*)#(\d*)\)).?$/

  def initialize(entry_line)
    @content = entry_line
  end

  def to_s
    formatted_entry
  end

  private

  def formatted_entry
    text = @content
    text = formatted_issue_urls(text)
    text
  end

  def formatted_issue_urls(text)
    text.sub(CORE_ISSUE_HASH_REGEX, '[' + '\1' + ']' + '(' + GITHUB_CORE_ISSUE_BASE_URL + '\2)')
        .sub(WAGON_ISSUE_HASH_REGEX, '[' + '\1' + ']' + '(' + GITHUB_BASE_URL + '\2/issues/\3)')
  end
end
