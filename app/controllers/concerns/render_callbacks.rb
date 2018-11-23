# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Provide before_render callbacks.
module RenderCallbacks

  def self.included(controller)
    controller.extend ActiveModel::Callbacks
    controller.extend ClassMethods
    prepend Callback

    controller.define_render_callbacks :index
  end

  module Callback
    # Helper method to run before_render callbacks and render the action.
    # If a callback renders or redirects, the action is not rendered.
    def render(*args, &block)
      options = _normalize_render(*args, &block)
      callback = "render_#{options[:template]}"
      run_callbacks(callback) if respond_to?(:"_#{callback}_callbacks", true)

      super(*args, &block) unless performed?
    end
  end

  private

  # Helper method the run the given block in between the before and after
  # callbacks of the given kinds.
  def with_callbacks(*kinds, &block)
    kinds.reverse.inject(block) do |b, kind|
      -> { run_callbacks(kind, &b) }
    end.call
  end

  module ClassMethods
    # Defines before callbacks for the render actions.
    def define_render_callbacks(*actions)
      args = actions.collect { |a| :"render_#{a}" }
      args << { only: :before,
                terminator: ->(ctrl, result) { result == false || ctrl.performed? } }
      define_model_callbacks(*args)
    end
  end
end
