class GroupDecorator < BaseDecorator
  decorates :group

  include ContactableDecorator

  def possible_children_links
    model.class.possible_children.map do |type|
      link = h.new_group_path(group: { parent_id: self.id, type: type.sti_name})
      [type.model_name.human, link]
    end
  end

  def possible_role_links(external = false)
    model.class.roles.select {|r| r.external == external}.map do |type|
      link = h.new_group_role_path(self, role: { type: type.sti_name})
      [type.model_name.human, link]
    end
  end
  
  def people_filter_links
    model.all_people_filters.collect do |filter|
      link = h.group_people_path(kind: filter.kind, role_types: filter.role_types.collect(&:to_s))
      [filter.name, link]
    end << 
    nil << 
    ['Neuer Filter...', h.new_group_people_filter_path(id, people_filter: h.params.slice(:kind, :role_types))]
  end
  
  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }
  end

  def modifiable_attributes(*attributes)
    attributes = used_attributes(*attributes)
    attributes -= model.class.superior_attributes unless h.can?(:modify_superior, self)
    attributes
  end

  def children_order_by_type
    if children.present?
      charr = children.order_by_type
      ch2arr = []
      gt = ''
      charr.each do |c|
        if (c.type != gt)
          gt = c.type
          ch2arr.push(nil)
        end
        ch2arr.push(c)
      end
      ch2arr
    end
  end

end
