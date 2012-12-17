# encoding: utf-8

class GroupDecorator < ApplicationDecorator
  decorates :group
  decorates_association :contact

  include ContactableDecorator

  def prepend_complete_address(html)
    if contact
      html << "c/o #{contact}"
      html << h.tag(:br)
    end
  end

  def possible_children_links
    model.class.possible_children.map do |type|
      link = h.new_group_path(group: { parent_id: self.id, type: type.sti_name})
      h.link_to(type.model_name.human, link)
    end
  end

  def possible_role_links
    possible_roles.map do |entry|
      link = h.new_group_role_path(self, role: { type: entry[:sti_name]})
      h.link_to(entry[:human], link)
    end
  end

  def possible_roles
    model.class.role_types.map do |type|
      if !type.restricted &&
        (type.visible_from_above? || can?(:index_local_people, model))  # users from above cannot create external roles
        { sti_name: type.sti_name, human: type.model_name.human }
      end
    end.compact
  end

  def as_quicksearch
    {id: id, label: h.safe_join([parent.to_s.presence, to_s].compact, ' > '), type: :group}
  end

  ### EVENT
  def possible_events
    model.class.event_types
  end

  def event_link(et)
    h.new_group_event_path(event: {type: et.sti_name})
  end

  def new_event_button
    e = possible_events.first
    h.action_button("#{e.model_name.human} erstellen", event_link(e), :plus)
  end

  def new_event_dropdown
    h.dropdown_button('Anlass erstellen', possible_event_links, :plus)
  end

  def possible_event_links
    possible_events.map do |type|
      h.link_to(type.model_name.human, event_link(type))
    end
  end

  def new_event_dropdown_button
    event = events.new
    event.groups << model
    if can?(:new, event)
      possible_events.count == 1 ? new_event_button : new_event_dropdown
    end
  end

  def bottom?
    klass.possible_children.none?(&:layer)
  end

  def modifiable_attributes(*attributes)
    attributes = used_attributes(*attributes)
    attributes -= model.class.superior_attributes unless can?(:modify_superior, model)
    attributes
  end

  def type_name
    klass.model_name.human
  end

end
