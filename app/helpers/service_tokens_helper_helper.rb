# encoding: utf-8

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ServiceTokensHelperHelper

  def format_service_token_abilities(entry)
    content_tag(:ul, class: 'unstyled') do
      keys = %w(people people_below groups events).select { |key| entry.send(key) }
      safe_join(keys) do |key|
        content_tag(:li, t("service_tokens.abilities.#{key}"))
      end
    end
  end
end
