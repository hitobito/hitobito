module Jubla::Event::Kind
  extend ActiveSupport::Concern
  
  included do
    attr_accessible :j_s_label
  end
  
end
