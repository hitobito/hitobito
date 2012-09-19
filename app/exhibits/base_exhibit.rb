class BaseExhibit < DisplayCase::Exhibit
  extend Forwardable
  def_delegators :context, :content_tag, :can?

  # fixes issue https://github.com/objects-on-rails/display-case/issues/8
  def eql?(other)
    super || (self.respond_to?(:to_model) && other.respond_to?(:to_model) && (self.to_model == other.to_model))
  end
end
