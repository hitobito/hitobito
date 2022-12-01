class PhoneNumberResource < ApplicationResource
  attribute :label, :string
  attribute :public, :boolean

  attribute :contactable_id, :integer
  attribute :contactable_type, :string
  attribute :number, :string

  # needs to be in child class, since it will otherwise think the parent model is Contactable
  polymorphic_belongs_to :contactable do
    group_by(:contactable_type) do
      on(:Person)
    end
  end
end
