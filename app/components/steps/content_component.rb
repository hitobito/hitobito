# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Steps
  class ContentComponent < IteratingComponent
    with_collection_parameter :partial

    public :stimulus_action

    def initialize(partial:, partial_iteration:, step:, form:)
      super(iterator: partial_iteration, step: step)
      @form = form
      @partial = partial.to_s
    end

    def call
      content_tag(:div, markup, class: %W[step-content #{@partial.dasherize} #{active_class}])
    end

    def next_button(title = t('steps.steps_component.next_link'))
      helpers.submit_button(@form, title, name: :step, value: @index)
    end

    def back_link
      data = { action: stimulus_action(:back), index: @index - 1 }
      link_to(t('global.button.back'), '#', class: 'link cancel', data: data)
    end

    private

    def markup
      render(@partial, f: @form, c: self, required: false)
    end
  end
end
