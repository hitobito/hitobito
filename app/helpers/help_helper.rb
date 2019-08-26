# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module HelpHelper

  def get_help_text(*args)
    key = args.join('.')
    help_text_for_key(key)
  end

  def render_help_text(*args)
    help_text = get_help_text(args)
    return if help_text.nil?

    # TODO: Assess output security concerns
    content_tag :div, help_text[:content].html_safe, class: 'help-text alert alert-info'
  end

  private

  def help_text_for_key(key)
    (@help_texts || []).find { |ht| ht[:key] == key }
  end

end
