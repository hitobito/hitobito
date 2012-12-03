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
  
  validate :assert_required_placeholders_are_used
  
  class << self
    def get(key)
      find_by_key(key)
    end
  end
  
  def to_s
    label
  end
  
  def placeholders_list
    placeholders_required_list + placeholders_optional_list
  end
  
  def placeholders_required_list
    as_list(placeholders_required)
  end
  
  def placeholders_optional_list
    as_list(placeholders_optional)
  end
  
  def placeholder_token(key)
    "{#{key}}"
  end
  
  def body_with_values(placeholders = {})
    placeholders_list.each_with_object(body.dup) do |placeholder, output|
      token = placeholder_token(placeholder)
      if output.include?(token)
        if placeholders.key?(placeholder)
          output.gsub!(token, placeholders[placeholder])
        else
          raise ArgumentError, "Body contains placeholder #{token}, not given"
        end
      end
    end
  end
  
  private
  
  def as_list(placeholders)
    placeholders.to_s.split(',').collect(&:strip)
  end
  
  def assert_required_placeholders_are_used
    placeholders_required_list.each do |placeholder|
      unless body.include?(placeholder_token(placeholder))
        errors.add(:body, "muss den Platzhalter #{placeholder_token(placeholder)} enthalten")
      end
    end
  end
end
