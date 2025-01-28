#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays::People
  class LayerGroupLabelColumn < TableDisplays::Column
    def required_permission(attr)
      :show
    end

    def required_model_attrs(attr)
      ["people.contact_data_visible"]
    end

    def render(attr)
      super do |target, target_attr|
        layer_group(target, target_attr)
      end
    end

    def allowed_value_for(target, target_attr, &block)
      layer_group(target, target_attr)
    end

    def sort_by(attr)
      nil
    end

    def layer_group(target, target_attr)
      if template
        template.format_attr(target, target_attr) if target.respond_to?(target_attr)
      else
        target.layer_group.name
      end
    end
  end
end
