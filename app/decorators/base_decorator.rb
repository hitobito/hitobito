class BaseDecorator < Draper::Base
  delegate :to_s, to: :model
  delegate :can?, :content_tag, to: :h

  ## custom access to model class
  # model_class from draper does not play well with STI
  def klass
    model.class
  end
end
