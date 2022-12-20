#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Graphiti::Adapters::ActiveRecord.class_eval do
  def associate_all(parent, children, association_name, association_type)
    if activerecord_associate?(parent, children[0], association_name)
      association = parent.association(association_name)
      association.loaded!

      children.each do |child|
        if association_type == :many_to_many &&
          [:create, :update].include?(Graphiti.context[:namespace]) &&
          !parent.send(association_name).exists?(child.id) &&
          child.errors.blank?
          parent.send(association_name) << child
        else
          target = association.instance_variable_get(:@target)
          target = [child] | target   # only this line is changed
          # target |= [child]         # was this in original graphiti code
          association.instance_variable_set(:@target, target)
        end
      end
    else
      super
    end
  end
end
