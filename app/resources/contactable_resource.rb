# TODO This is currently not used since graphiti seems to get confused about base classes
# for polymorphic relations.
# Thus, the json api type was always contactable and the relation couldn't be correctly mapped.
# Tried abstract_class = true, that didn't work either
class ContactableResource < ApplicationResource
  attribute :label, :string
  attribute :public, :boolean

  attribute :contactable_id, :integer
  attribute :contactable_type, :string
end
