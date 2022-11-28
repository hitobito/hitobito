class PersonResource < ApplicationResource
  primary_endpoint 'people', [:index, :show, :update]

  attribute :first_name, :string
  attribute :last_name, :string
  attribute :nickname, :string
  attribute :company_name, :string
  attribute :company, :boolean
  attribute :email, :string
  attribute :address, :string
  attribute :zip_code, :string
  attribute :town, :string
  attribute :country, :string
  attribute :gender, :string
  attribute :birthday, :date
  attribute :primary_group_id, :integer
end
