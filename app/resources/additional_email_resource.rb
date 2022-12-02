class AdditionalEmailResource < ApplicationResource
  include ContactableResource

  attribute :email, :string
end
