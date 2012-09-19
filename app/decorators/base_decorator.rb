class BaseDecorator < Draper::Base
  delegate :to_s, to: :model

end
