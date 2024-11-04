class MessageTemplate < ApplicationRecord
  belongs_to :templated, polymorphic: true

  validates :title, presence: true

  def option_for_select(data_map: {title: :title, body: :description})
    [title, id, data: {data_map[:title] => title, data_map[:body] => body}]
  end
end
