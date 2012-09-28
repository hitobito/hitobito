module Jubla::GroupsController 
  extend ActiveSupport::Concern

  included do 
    before_render_form :load_advisors
  end

  def load_advisors
    return unless entry.kind_of?(Group::Flock) 
    @coaches = entry.available_coaches.only_public_data.order_by_name
    @advisors = entry.available_advisors.only_public_data.order_by_name
  end
end
