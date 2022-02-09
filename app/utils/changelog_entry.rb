# frozen_string_literal: true

#  Copyright (c) 2022, Stiftung für junge Auslandschweizer. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangelogEntry
  # rubocop:disable Metrics/LineLength
  GITHUB_BASE_URL = 'https://github.com/'
  GITHUB_CORE_ISSUE_BASE_URL = GITHUB_BASE_URL + 'hitobito/hitobito/issues/'

  CORE_ISSUE_HASH_REGEX = /(\(#(\d*)\))\S?/
  WAGON_ISSUE_HASH_REGEX = /(\((hitobito_\w*)#(\d*)\))\S?/

  GITHUB_USERNAME_REGEX = /(@([a-zA-Z0-9-]*))/

  URL_REGEX =  /(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9(!@:%_\+.~#?&\/\/=]*))/
  # rubocop:enable Metrics/LineLength

  def initialize(entry_line)
    @content = entry_line
  end

  def to_markdown
    markdown = @content
    markdown = formatted_urls(markdown)
    markdown = formatted_issue_links(markdown)
    markdown = formatted_user_links(markdown)
    markdown
  end

  private

  def formatted_issue_links(text)
    text.sub(CORE_ISSUE_HASH_REGEX, '[\1]' + '(' + GITHUB_CORE_ISSUE_BASE_URL + '\2)')
        .sub(WAGON_ISSUE_HASH_REGEX, '[\1]' + '(' + GITHUB_BASE_URL + 'hitobito/\2/issues/\3)')
  end

  def formatted_user_links(text)
    text.sub(GITHUB_USERNAME_REGEX, '[\1]' + '(' + GITHUB_BASE_URL + '\2)')
  end

  def formatted_urls(text)
    text.sub(URL_REGEX, '<\1>')
  end
end
