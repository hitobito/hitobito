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
  attribute :primary_group_id, :integer, except: [:writeable]

  has_many :phone_numbers
  has_many :social_accounts
  has_many :additional_emails

  filter :updated_at, :datetime, single: true do
    eq do |scope, value|
      scope.where(updated_at: value..)
    end
  end
end
