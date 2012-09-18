require 'display_case'
require 'forwardable'
class BaseExhibit < DisplayCase::Exhibit
  extend Forwardable
  def_delegators :context, :content_tag, :can?

  def inspect
    "Exhibit[#{__getobj__.inspect}]"
  end
end
