class ApplicationDecorator < Draper::Base
  delegate :to_s, to: :model
  delegate :can?, :content_tag, :safe_join, :current_user, to: :h

  ## custom access to model class
  # model_class from draper does not play well with STI
  def klass
    model.class
  end
  
  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }.map(&:to_s)
  end

  def used?(attribute)
    used_attributes(attribute).each { |a| yield }
  end
end
