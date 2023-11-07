# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Steps
  class IteratingComponent < ApplicationComponent
    attr_reader :current_step

    def initialize(step:, iterator:)
      @step = step
      @index = iterator.index
    end

    private

    def active_class
      'active' if active?
    end

    def active?
      @index == @step
    end

    def stimulus_controller
      StepsComponent.name.underscore.gsub('/', '--').tr('_', '-')
    end
  end
end
