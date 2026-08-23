# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module NavigationHelper
  class Item
    attr_reader :model, :label_key, :path, :condition, :active_for_override

    def initialize(**attrs)
      @model = attrs[:model]
      @path = attrs.fetch(:path)
      @label_key = attrs[:label]
      @condition = attrs[:if]
      @active_for_override = attrs[:active_for]
    end

    def visible?(view)
      if condition
        view.instance_eval(&condition)
      elsif model
        view.can?(:index, model)
      else
        true
      end
    end

    def label(view)
      return model.model_name.human(count: 2) unless label_key

      view.t(label_key, application_name: Settings.application.name)
    end

    def url(view)
      path.is_a?(Proc) ? view.instance_eval(&path) : view.send(path)
    end

    def active_for(view)
      active_for_override || url(view).delete_prefix("/").split("?").first
    end

    def current?(view)
      view.send(:section_active?, url(view), [active_for(view)])
    end
  end
end
