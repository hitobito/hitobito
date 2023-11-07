# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Steps
  class HeaderComponent < IteratingComponent
    with_collection_parameter :content_component

    def initialize(content_component:, content_component_iteration:, step:)
      super(iterator: content_component_iteration, step: step)
      @content_component = content_component
    end

    def call
      content_tag(:li, markup, class: active_class)
    end

    private

    def markup
      return title unless @index <= @step

      link_to(title, '#', data: { action: stimulus_action(:activate) })
    end

    def title
      @content_component.title
    end
  end
end
