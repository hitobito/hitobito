class WebauthnCredential < ApplicationRecord
  validates_by_schema

  belongs_to :user
end
