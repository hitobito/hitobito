# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class StepsComponent::IteratingComponent < ApplicationComponent
  attr_reader :current_step

  delegate :index, :first?, :last?, to: "@iterator"

  def initialize(step:, iterator:)
    @step = step
    @iterator = iterator
  end

  private

  def active_class
    "active" if active?
  end

  def active?
    index == @step
  end

  def stimulus_controller
    StepsComponent.name.underscore.gsub("/", "--").tr("_", "-")
  end
end
