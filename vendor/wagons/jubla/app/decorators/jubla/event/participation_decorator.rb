module Jubla::Event::ParticipationDecorator
  extend ActiveSupport::Concern
  
  included do
    alias_method_chain :qualification_link, :status
  end
  
  def qualification_link_with_status
    if event.completed? || event.closed?
      h.icon(qualified? ? :ok : :minus)
    else
      qualification_link_without_status
    end
  end
  
  
end