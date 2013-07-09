module Jubla::Event::ParticipationDecorator
  extend ActiveSupport::Concern

  included do
    alias_method_chain :qualification_link, :status
    alias_method_chain :originating_group, :state
  end

  def qualification_link_with_status(group)
    if event.qualification_possible?
      qualification_link_without_status(group)
    else
      h.icon(qualified? ? :ok : :minus)
    end
  end

  def originating_group_with_state
    if group = person.primary_group
      group.layer_hierarchy[1] # second layer are states
    end
  end

end