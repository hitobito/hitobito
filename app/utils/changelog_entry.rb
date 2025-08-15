# frozen_string_literal: true

#  Copyright (c) 2022, Stiftung für junge Auslandschweizer. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangelogEntry
  GITHUB_BASE_URL = "https://github.com/"
  GITHUB_CORE_ISSUE_BASE_URL = GITHUB_BASE_URL + "hitobito/hitobito/issues/"

  # rubocop:todo Layout/LineLength
  CORE_ISSUE_HASH_REGEX = /(?<!\w)(?<!\/)(?:hitobito)?#(?<number>\d+)\b/ # matches e.g (#42) or 'hitobito#42'
  # rubocop:enable Layout/LineLength
  # rubocop:todo Layout/LineLength
  WAGON_ISSUE_HASH_REGEX = /(?<!\w)(?<!\/)(?:hitobito\/|\b)(?<wagon>\w*_\w*)#(?<number>\d+)\b/ # matches e.g (hitobito_generic#42) or (hitobito_sjas#1000)
  # rubocop:enable Layout/LineLength

  # rubocop:todo Layout/LineLength
  GITHUB_USERNAME_REGEX = /@(?<gh_user>[a-zA-Z0-9-]*)/ # matches e.g @TheWalkingLeek or @kronn, used charset according to github username policies
  # rubocop:enable Layout/LineLength

  # rubocop:todo Layout/LineLength
  URL_REGEX = /(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9(!@:%_\+.~#?&\/=]*))/ # matches e.g https://hitobito.com
  # rubocop:enable Layout/LineLength

  def self.markdown_link(url:, label: url) = "[#{label}](#{url})"

  class_attribute :regex_substitutions, default: {
    # Core tickets
    CORE_ISSUE_HASH_REGEX => markdown_link(label: 'hitobito#\k<number>',
      url: GITHUB_CORE_ISSUE_BASE_URL + '\k<number>'),
    # Wagon tickets
    WAGON_ISSUE_HASH_REGEX => markdown_link(label: '\k<wagon>#\k<number>',
      url: GITHUB_BASE_URL + 'hitobito/\k<wagon>/issues/\k<number>'),
    # Github Usernames, matches e.g. @TheWalkingLeek or @kronn
    GITHUB_USERNAME_REGEX => markdown_link(label: '@\k<gh_user>',
      url: GITHUB_BASE_URL + '\k<gh_user>')

  }

  def initialize(entry_line)
    @content = entry_line
  end

  def to_markdown
    regex_substitutions.reduce(@content) do |text, (regex, replacement)|
      text.gsub(regex, replacement)
    end
  end
end
