# Exhibit for all active record objects
class ModelExhibit < DisplayCase::Exhibit
  
  def self.applicable_to?(object)
    object.kind_of?(ActiveRecord::Base)
  end
  
  # This method is required so that exhibits play nice with cancan
  def kind_of?(klass)
    klass >= self.class ? true : super
  end
  
  # fixes issue https://github.com/objects-on-rails/display-case/issues/8
  def eql?(other)
    super || (self.respond_to?(:to_model) && other.respond_to?(:to_model) && (self.to_model == other.to_model))
  end
  alias :== eql?
  
end