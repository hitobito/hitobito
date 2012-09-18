require 'display_case'
require 'forwardable'
class BaseExhibit < DisplayCase::Exhibit
  extend Forwardable
  def_delegators :context, :content_tag, :can?

  def kind_of?(klass)
    klass >= self.class ? true : super
  end

  def inspect
    "Exhibit[#{__getobj__.inspect}]"
  end
end
