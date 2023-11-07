# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Steps
  class ContentComponent < IteratingComponent
    with_collection_parameter :component

    public :stimulus_action

    attr_accessor :component

    def initialize(component:, component_iteration:, step:, form:, **args)
      super(iterator: component_iteration, step: step)
      @component = component
      @form = form
      @args = args
    end

    def next_button(title = t('steps.steps_component.next_link'))
      helpers.submit_button(@form, title, name: :step, value: @index)
    end

    def back_link
      data = { action: stimulus_action(:back), index: @index - 1 }
      link_to(t('global.button.back'), '#', class: 'link cancel', data: data)
    end
  end
end
