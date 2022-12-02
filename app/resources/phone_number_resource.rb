class PhoneNumberResource < ApplicationResource
  include ContactableResource

  attribute :number, :string
end
