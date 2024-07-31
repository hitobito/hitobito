# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class StepsComponent::HeaderComponent < StepsComponent::IteratingComponent
  def initialize(header:, header_iteration:, step:)
    super(iterator: header_iteration, step: step)
    @header = header
  end

  def call
    content_tag(:li, markup,
      class: active_class,
      data: stimulus_target("stepHeader"))
  end

  def render?
    !(first? && last?)
  end

  private

  def markup
    title
  end

  def title
    ti("#{@header}_title")
  end
end
