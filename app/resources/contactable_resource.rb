# Can not be a base class since graphiti seems to get confused about base classes
# for polymorphic relations.
# Thus, the json api type was always contactable and the relation couldn't be correctly mapped.
# Tried abstract_class = true, that didn't work either
module ContactableResource
  extend ActiveSupport::Concern

  included do
    attribute :label, :string
    attribute :public, :boolean

    attribute :contactable_id, :integer
    attribute :contactable_type, :string

    polymorphic_belongs_to :contactable do
      group_by(:contactable_type) do
        on(:Person)
      end
    end
  end
end
