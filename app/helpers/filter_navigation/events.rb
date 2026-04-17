# frozen_string_literal: true

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  class Events < Base
    delegate :params, to: :template
    delegate :name, to: :filter

    attr_reader :group, :filter

    def initialize(template, group, filter = {})
      super(template)
      @group = group
      @filter = filter
      init_labels
      init_items
    end

    private

    def init_labels
      @active_label = if name.present?
        dropdown.activate(name)
      elsif filter.chain.present?
        translate(:filter).tap do |label|
          dropdown.activate(label)
        end
      else
        label_for_range(params.fetch(:range, "deep"))
      end
    end

    def init_items
      range_item("deep")
      if group.layer? && group.has_sublayers?
        range_item("layer")
      end
      init_dropdown_links
    end

    def range_item(name)
      item(label_for_range(name), range_filter_path(name))
    end

    def label_for_range(range)
      template.t("filter_navigation/events.#{range}", layer: @group.layer_group.name)
    end

    def range_filter_path(name)
      template.url_for(
        params
          .to_unsafe_h
          .merge(range: name, only_path: true)
          .except(:filters, :returning, :name)
      )
    end

    def init_dropdown_links
      add_define_event_filter_link
    end

    def add_define_event_filter_link
      dropdown.add_divider if dropdown.items.present?
      dropdown.add_item(translate(:filter), new_event_filter_path)
    end

    def new_event_filter_path
      template.send(
        :"new_group_events_#{filter.event_type.type_name}_filter_path",
        group.id,
        year: filter.year,
        range: filter.range,
        filters: filter.chain.to_params
      )
    end
  end
end
