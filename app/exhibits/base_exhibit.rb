class BaseExhibit < DisplayCase::Exhibit
  extend Forwardable
  def_delegators :context, :content_tag, :can?


end
