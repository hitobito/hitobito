class ContactableResource < ApplicationResource
  primary_endpoint 'people', [:index, :show, :update]

  attribute :number, :string
  attribute :label, :string
  attribute :public, :boolean
end
