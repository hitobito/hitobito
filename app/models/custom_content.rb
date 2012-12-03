# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  key                   :string(255)      not null
#  label                 :string(255)      not null
#  subject               :string(255)
#  body                  :text
#  placeholders_required :string(255)
#  placeholders_optional :string(255)
#

class CustomContent < ActiveRecord::Base
  attr_accessible :body, :subject
  
  class << self
    def get(key)
      find_by_key(key)
    end
  end
  
  def to_s
    label
  end
  
end
