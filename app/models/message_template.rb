class MessageTemplate < ApplicationRecord
  belongs_to :templated, polymorphic: true
end
