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
  attribute :gender, :string, readable: :show_details?
  attribute :birthday, :date, readable: :show_details?
  attribute :primary_group_id, :integer, except: [:writeable]

  has_many :phone_numbers, link: false, resource: PhoneNumberResource, readable: :show_details_or_public?
  has_many :social_accounts, link: false, resource: SocialAccountResource, readable: :show_details_or_public?
  has_many :additional_emails, link: false, resource: AdditionalEmailResource, readable: :show_details_or_public?

  filter :updated_at, :datetime, single: true do
    eq do |scope, value|
      scope.where(updated_at: value..)
    end
  end

  def show_details?(model_instance)
    can?(:show_details, model_instance)
  end

  def show_details_or_public(model_instance)
    show_details?(model_instance) || model_instance.public?
  end
end
