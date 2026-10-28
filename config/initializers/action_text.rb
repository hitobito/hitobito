# frozen_string_literal: true

#  Copyright (c) 2020-2026, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ActionText::ContentHelper
  module AutoLink
    def sanitize_action_text_content(content)
      super(ActionText::Content.new(auto_link(content.to_html, sanitize: false)))
    end
  end

  prepend AutoLink
end

# See https://github.com/rails/rails/issues/37672 - this issue was affecting the specs
ActiveSupport.on_load(:action_view) do
  include ActionText::ContentHelper
  include ActionText::TagHelper
end

ActiveSupport.on_load :action_text_rich_text do
  has_paper_trail if: ->(rich_text) { rich_text.record.respond_to?(:paper_trail_rich_text_meta) },
    meta: {
      main_id: ->(rich_text) { rich_text.record.paper_trail_rich_text_meta[:main_id] },
      main_type: ->(rich_text) { rich_text.record.paper_trail_rich_text_meta[:main_type] },
      item_label: ->(rich_text) { rich_text.record.paper_trail_rich_text_meta[:item_label] }
    },
    only: [:body]

  before_save do
    self.plain_text_body = body&.to_plain_text.presence if respond_to?(:plain_text_body=)
  end
end

Rails.application.config.after_initialize do

  # Only allow tags that are supported in Trix.
  # List based on the following files in Trix:
  # https://github.com/basecamp/trix/blob/master/src/trix/config/block_attributes.coffee
  # https://github.com/basecamp/trix/blob/master/src/trix/config/text_attributes.coffee
  ActionText::ContentHelper.allowed_tags = Set.new([
      "div",
      "blockquote",
      "h1",
      "pre",
      "ul",
      "ol",
      "li",
      "strong",
      "em",
      "a",
      "del",
      Rails.application.config.action_text.attachment_tag_name,
      "figure",
      "figcaption",
      "img",
      "br"
  ]).freeze
end
