# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  class Events < Base

    def initialize(template, group)
      super(template)
      @group = group
      init_items
    end

    def active_label
      label_for_filter(template.params.fetch(:filter, 'all'))
    end

    private

    def init_items
      filter_item('all')
      filter_item('layer')
    end

    def filter_item(name)
      item(label_for_filter(name), filter_path(name))
    end

    def label_for_filter(filter)
      template.t("filter_navigation/events.#{filter}", layer: @group.layer_group.name)
    end

    def filter_path(name)
      template.url_for(template.params.to_unsafe_h.merge(filter: name, only_path: true))
    end

  end
end
