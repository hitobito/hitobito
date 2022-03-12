# frozen_string_literal: true

#  Copyright (c) 2022, Stiftung für junge Auslandschweizer. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangelogEntry
  # rubocop:disable Metrics/LineLength
  GITHUB_BASE_URL = 'https://github.com/'
  GITHUB_CORE_ISSUE_BASE_URL = GITHUB_BASE_URL + 'hitobito/hitobito/issues/'

  CORE_ISSUE_HASH_REGEX = /(\(#(\d*)\))\S?/ # matches e.g (#42)
  WAGON_ISSUE_HASH_REGEX = /(\((hitobito_\w*)#(\d*)\))\S?/ # matches e.g (hitobito_generic#42) or (hitobito_sjas#1000)

  GITHUB_USERNAME_REGEX = /(@([a-zA-Z0-9-]*))/ # matches e.g @TheWalkingLeek or @kronn, used charset according to github username policies

  URL_REGEX =  /(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9(!@:%_\+.~#?&\/\/=]*))/ # matches e.g https://hitobito.com
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
    # (#42) => [(#42)](https://github.com/hitobito/hitobito/issues/42)
    # (hitobito_generic#42) => [(hitobito_generic#42)](https://github.com/hitobito/hitobito_generic/issues/42)
    text.sub(CORE_ISSUE_HASH_REGEX, '[\1]' + '(' + GITHUB_CORE_ISSUE_BASE_URL + '\2)')
        .sub(WAGON_ISSUE_HASH_REGEX, '[\1]' + '(' + GITHUB_BASE_URL + 'hitobito/\2/issues/\3)')
  end

  def formatted_user_links(text)
    # @TheWalkingLeek => [@TheWalkingLeek](https://github.com/TheWalkingLeek)
    text.sub(GITHUB_USERNAME_REGEX, '[\1]' + '(' + GITHUB_BASE_URL + '\2)')
  end

  def formatted_urls(text)
    # https://hitobito.com => <https://hitobito.com>
    text.sub(URL_REGEX, '<\1>')
  end
end
