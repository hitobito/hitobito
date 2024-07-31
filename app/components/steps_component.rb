# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class StepsComponent < ApplicationComponent
  renders_many :headers, "HeaderComponent"
  renders_many :steps, "StepComponent"
  renders_one :aside
  renders_one :footer

  attr_accessor :step, :partials

  def initialize(step:, form:, partials: [])
    @partials = partials
    @step = step
    @form = form
  end

  def render?
    @partials.present?
  end

  def model
    @form.object
  end
end
