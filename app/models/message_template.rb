class MessageTemplate < ApplicationRecord
  belongs_to :templated, polymorphic: true

  def option_for_select
    [title, id, data: {title: title, description: body}]
  end
end
