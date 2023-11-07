# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Steps
  class StepsComponent < ApplicationComponent
    renders_many :headers, 'Steps::HeaderComponent'
    renders_many :steps, 'Steps::ContentComponent'

    attr_accessor :step, :steps

    def initialize(steps: [], step:, form:, **args)
      @steps = steps
      @step = step
      @form = form
      @args = args
    end

    def render?
      @steps.present?
    end
  end
end
